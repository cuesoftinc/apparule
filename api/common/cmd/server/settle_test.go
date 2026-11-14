package main

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// A write is answered only after its outbox rows are published: the client
// must not see a header while the flush is still running (S-14).
func TestResponseWaitsForTheFlush(t *testing.T) {
	release := make(chan struct{})
	flushing := make(chan struct{})
	var flushed atomic.Bool
	flush := func(context.Context) {
		close(flushing)
		<-release
		flushed.Store(true)
	}
	h := flushBeforeResponse(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(strings.Repeat("x", 1<<20)))
		if f, ok := w.(http.Flusher); ok {
			f.Flush()
		}
	}), flush)
	srv := httptest.NewServer(h)
	defer srv.Close()

	type result struct {
		res *http.Response
		err error
	}
	done := make(chan result, 1)
	go func() {
		res, err := http.Post(srv.URL+"/api/v1/posts", "application/json", strings.NewReader("{}"))
		done <- result{res, err}
	}()
	<-flushing
	select {
	case r := <-done:
		t.Fatalf("client got a response (%v, %v) while the outbox flush was still running", r.res, r.err)
	case <-time.After(200 * time.Millisecond):
	}
	close(release)
	r := <-done
	if r.err != nil {
		t.Fatal(r.err)
	}
	defer r.res.Body.Close()
	if !flushed.Load() {
		t.Fatal("response arrived before the flush finished")
	}
	body, _ := io.ReadAll(r.res.Body)
	if r.res.StatusCode != http.StatusCreated || len(body) != 1<<20 {
		t.Fatalf("response = %d with %d bytes; want 201 with the whole body", r.res.StatusCode, len(body))
	}
}

func TestFlushRunsPerRequestKind(t *testing.T) {
	cases := []struct {
		name, method, path string
		queue              bool
		want               int
	}{
		{"write", http.MethodPost, "/api/v1/posts", false, 1},
		{"patch", http.MethodPatch, "/api/v1/me", false, 1},
		{"delete", http.MethodDelete, "/api/v1/posts/1", false, 1},
		{"webhook", http.MethodPost, "/webhooks/payments", false, 1},
		{"plain read", http.MethodGet, "/api/v1/feed", false, 0},
		{"read that queued", http.MethodGet, "/api/v1/sessions/1", true, 1},
		{"options", http.MethodOptions, "/api/v1/feed", false, 0},
		{"internal write", http.MethodPost, "/internal/jobs/captures", false, 0},
		{"internal that queued", http.MethodPost, "/internal/settle", true, 0},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			var n int
			h := flushBeforeResponse(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if c.queue {
					repository.NoteQueued(r.Context())
				}
				w.WriteHeader(http.StatusOK)
			}), func(context.Context) { n++ })
			h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(c.method, c.path, nil))
			if n != c.want {
				t.Fatalf("%s %s flushed %d times; want %d", c.method, c.path, n, c.want)
			}
		})
	}
}

// A handler that never writes still flushes before the empty answer.
func TestFlushRunsForAnEmptyAnswer(t *testing.T) {
	var n int
	h := flushBeforeResponse(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}), func(context.Context) { n++ })
	h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/api/v1/posts", nil))
	if n != 1 {
		t.Fatalf("flushed %d times; want 1", n)
	}
}

// The flush outlives a client that gave up: the rows are already committed.
func TestFlushIsNotCutShortByTheClientLeaving(t *testing.T) {
	var flushErr error
	h := flushBeforeResponse(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}), func(ctx context.Context) { flushErr = ctx.Err() })
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/api/v1/posts", nil).WithContext(ctx))
	if flushErr != nil {
		t.Fatalf("flush context = %v; want it detached from the request's cancellation", flushErr)
	}
}

type steps struct {
	rounds   []bool // caught up, per drain
	sent     []int  // rows sent, per flush
	flushErr error
	order    []string
	budgets  []time.Duration
}

func (s *steps) settler(budget time.Duration) settler {
	return settler{
		budget: budget,
		drain: func(_ context.Context, b time.Duration) bool {
			s.order = append(s.order, "drain")
			s.budgets = append(s.budgets, b)
			ok := s.rounds[0]
			s.rounds = s.rounds[1:]
			return ok
		},
		flush: func(context.Context) (int, error) {
			s.order = append(s.order, "flush")
			n := s.sent[0]
			s.sent = s.sent[1:]
			return n, s.flushErr
		},
	}
}

func TestSettleDrainsPublishesAndDrainsAgainForTheResults(t *testing.T) {
	s := &steps{rounds: []bool{true, true}, sent: []int{2, 0}}
	if !s.settler(time.Minute).run(context.Background()) {
		t.Fatal("settle = false; want caught up once a round publishes nothing")
	}
	want := "drain flush drain flush"
	if got := strings.Join(s.order, " "); got != want {
		t.Fatalf("order = %q; want %q (results the publish caused are drained)", got, want)
	}
}

func TestSettleStopsAfterItsRoundsWhenWorkKeepsComing(t *testing.T) {
	s := &steps{rounds: []bool{true, true, true, true, true}, sent: []int{1, 1, 1, 1, 1}}
	if s.settler(time.Minute).run(context.Background()) {
		t.Fatal("settle = true while every round still published; want false")
	}
	if len(s.order) != 2*settleRounds {
		t.Fatalf("ran %v; want %d rounds", s.order, settleRounds)
	}
}

func TestSettleIsNotCaughtUpWhileAConsumerIsBehind(t *testing.T) {
	s := &steps{rounds: []bool{false, false, false, false}, sent: []int{0, 0, 0, 0}}
	if s.settler(time.Minute).run(context.Background()) {
		t.Fatal("settle = true with a consumer behind")
	}
}

func TestSettleReportsAFailedFlushAndStops(t *testing.T) {
	s := &steps{rounds: []bool{true, true}, sent: []int{0, 0}, flushErr: errors.New("kafka away")}
	if s.settler(time.Minute).run(context.Background()) {
		t.Fatal("settle = true after the flush failed")
	}
	if len(s.order) != 2 {
		t.Fatalf("ran %v; want it to stop at the failed flush", s.order)
	}
}

func TestEachDrainGetsHalfOfWhatIsLeft(t *testing.T) {
	s := &steps{rounds: []bool{true}, sent: []int{0}}
	s.settler(10 * time.Second).run(context.Background())
	if len(s.budgets) != 1 || s.budgets[0] > 5*time.Second || s.budgets[0] < 4*time.Second {
		t.Fatalf("drain budget = %v; want about 5s of a 10s settle", s.budgets)
	}
}
