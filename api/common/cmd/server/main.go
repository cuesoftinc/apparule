// Command server is api/common: the HTTP API, the Kafka consumers and the
// outbox publisher in one process (system-design.md §4). In cloud it scales
// to zero on request-based CPU (S-14): it publishes the outbox before a
// response, settles segmentation and commerce in turn (shared-messaging.md),
// and drains its own consumers inside POST /internal/settle, which Cloud
// Scheduler's captures job and uploads call. Cloud Scheduler calls
// POST /internal/jobs/{name} on it.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"slices"
	"strings"
	"syscall"
	"time"

	"golang.org/x/sync/errgroup"

	"github.com/cuesoftinc/apparule/api/common/internal/app"
	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/handler"
	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/middleware"
	"github.com/cuesoftinc/apparule/api/common/internal/outbox"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
	"github.com/cuesoftinc/apparule/api/common/internal/router"
	"github.com/cuesoftinc/apparule/api/common/internal/wake"
	"github.com/cuesoftinc/apparule/api/common/migrations"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	if err := run(); err != nil {
		slog.Error("exiting", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if err := cfg.RequireAuth(); err != nil {
		return err
	}
	a, err := app.New(ctx, cfg)
	if err != nil {
		return err
	}
	defer a.Close()

	if err := migrations.Apply(ctx, a.DB.Pool); err != nil {
		return err
	}

	producer, err := kafka.NewProducer(cfg.Kafka, a.Contract, a.Store)
	if err != nil {
		return err
	}
	defer producer.Close()
	waker := wake.New()
	wakeFor := func(event string) string {
		if event == kafka.EventCaptureReady {
			return cfg.Wake.Segmentation
		}
		return cfg.Wake.Commerce // every other request goes to commerce
	}
	// On request-based CPU nothing runs between requests: the publisher and
	// the consumers work inside a request or a settle, and a flush settles
	// the services it published for. Where CPU is always allocated they loop.
	settleOnRequest := cfg.OnCloudRun
	publisher := &outbox.Publisher{DB: a.DB, Producer: producer, Interval: time.Second}
	if settleOnRequest {
		publisher.Wake = func(ctx context.Context, events []string) {
			bases := make([]string, 0, len(events))
			for _, event := range events {
				bases = append(bases, wakeFor(event))
			}
			waker.SettleAll(ctx, strings.Join(events, ","), bases...)
		}
	}

	s := a.Services
	consumers := map[string]map[string]kafka.Handler{
		kafka.TopicUploads: {
			kafka.EventCaptureUploaded: s.OnCaptureUploaded,
			kafka.EventMediaUploaded:   s.OnMediaUploaded,
		},
		kafka.TopicResults: {
			kafka.EventCaptureMeasured: s.OnCaptureMeasured,
			kafka.EventPaymentsOutcome: s.OnPaymentOutcome,
		},
	}
	failures := map[string]kafka.Failure{
		kafka.EventCaptureUploaded: s.OnCaptureUploadedFailed,
		kafka.EventCaptureMeasured: s.OnCaptureMeasuredFailed,
		kafka.EventPaymentsOutcome: s.OnPaymentOutcomeFailed,
	}
	var running []*kafka.Consumer
	for topic, handlers := range consumers {
		c, err := kafka.NewConsumer(cfg.Kafka, "apparule-common", topic, handlers, failures, a.Contract, a.Store)
		if err != nil {
			return err
		}
		running = append(running, c)
	}

	sso := handler.NewAuthHandler(cfg, s, ratelimit.NewSSOStore(a.Limiter), auth.NewGoogleSSO(cfg.Auth.GoogleClientID, cfg.Auth.GoogleClientSecret))
	ready := func(ctx context.Context) error {
		if err := a.DB.Ping(ctx); err != nil {
			return err
		}
		if settleOnRequest {
			return nil // consumers run inside a settle, not between requests
		}
		for _, c := range running {
			if !c.Running() {
				return errors.New("consumer stopped")
			}
		}
		return nil
	}
	settle := settler{
		drain: func(ctx context.Context, budget time.Duration) bool {
			caughtUp := make([]bool, len(running))
			var dg errgroup.Group
			for i, c := range running {
				dg.Go(func() error {
					ok, err := c.Drain(ctx, budget)
					if err != nil {
						slog.WarnContext(ctx, "consumer not caught up; the next pass continues", "step", "settle", "error", err)
					}
					caughtUp[i] = ok
					return nil
				})
			}
			_ = dg.Wait()
			return !slices.Contains(caughtUp, false)
		},
		flush:  publisher.Flush,
		budget: settleBudget,
	}
	jobs := &handler.Jobs{Run: a.Jobs(false, func(ctx context.Context) {
		if !settle.run(ctx) {
			slog.WarnContext(ctx, "settle did not catch up; the next pass continues", "step", "settle")
		}
	}), Verifier: handler.NewGoogleVerifier(), Audience: cfg.SchedulerAudience, Invoker: cfg.SchedulerInvokerEmail}
	settles := &handler.Settle{Run: settle.run, Verifier: handler.NewGoogleVerifier(), Audience: cfg.SchedulerAudience,
		Invokers: append([]string{cfg.SchedulerInvokerEmail}, cfg.SettleInvokerEmails...)}
	var api http.Handler = router.New(&handler.Handlers{S: s}, sso, middleware.Authenticate(cfg, s), cfg.CORSOrigins, ready, jobs, settles)
	if settleOnRequest {
		api = flushBeforeResponse(api, func(ctx context.Context) {
			if _, err := publisher.Flush(ctx); err != nil {
				slog.WarnContext(ctx, "outbox flush failed; the next pass retries", "step", "outbox", "error", err)
			}
		})
	}
	srv := &http.Server{Addr: ":" + cfg.Port, Handler: api, ReadHeaderTimeout: 10 * time.Second}

	g, gctx := errgroup.WithContext(ctx)
	if !settleOnRequest {
		g.Go(func() error { publisher.Run(gctx); return nil })
		for _, c := range running {
			g.Go(func() error { return c.Run(gctx) })
		}
	}
	g.Go(func() error {
		slog.Info("listening", "addr", srv.Addr)
		if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	})
	g.Go(func() error {
		<-gctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		return srv.Shutdown(shutdown)
	})
	// Consumers return only when gctx ends: a failing message is retried,
	// recorded and committed, never a reason to take the HTTP API down.
	return g.Wait()
}
