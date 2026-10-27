// Command server is api/common: the HTTP API, the Kafka consumers and the
// outbox publisher in one process (system-design.md §4). In cloud it scales
// to zero: whatever publishes for it wakes it, and it wakes segmentation and
// commerce in turn (shared-messaging.md). Cloud Scheduler calls
// POST /internal/jobs/{name} on it.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
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
	publisher := &outbox.Publisher{DB: a.DB, Producer: producer, Interval: time.Second,
		Wake: func(event string) { waker.Async(wakeFor(event), event) }}

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

	verifier := auth.NewVerifier(cfg.FirebaseProjectID, cfg.FirebaseEmulatorHost != "")
	ready := func(ctx context.Context) error {
		if err := a.DB.Ping(ctx); err != nil {
			return err
		}
		for _, c := range running {
			if !c.Running() {
				return errors.New("consumer stopped")
			}
		}
		return nil
	}
	jobs := &handler.Jobs{Run: a.Jobs(false), Verifier: handler.NewGoogleVerifier(),
		Audience: cfg.SchedulerAudience, Invoker: cfg.SchedulerInvokerEmail}
	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router.New(&handler.Handlers{S: s}, middleware.Authenticate(verifier, s), cfg.CORSOrigins, ready, jobs),
		ReadHeaderTimeout: 10 * time.Second,
	}

	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() error { publisher.Run(gctx); return nil })
	for _, c := range running {
		g.Go(func() error { return c.Run(gctx) })
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
