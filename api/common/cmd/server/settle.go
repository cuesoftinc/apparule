package main

import (
	"context"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const (
	// flushTimeout bounds publishing and settling before a response.
	flushTimeout = 30 * time.Second
	// settleBudget is one settle's time: the captures job (60 s attempt
	// deadline) runs its sweep first.
	settleBudget = 40 * time.Second
	// settleRounds caps the drain-then-publish rounds of one settle.
	settleRounds = 4
)

// commitWriter runs before once, ahead of the response's first byte.
type commitWriter struct {
	http.ResponseWriter
	before func()
	done   bool
}

func (c *commitWriter) commit() {
	if !c.done {
		c.done = true
		c.before()
	}
}

func (c *commitWriter) WriteHeader(code int) {
	c.commit()
	c.ResponseWriter.WriteHeader(code)
}

func (c *commitWriter) Write(b []byte) (int, error) {
	c.commit()
	return c.ResponseWriter.Write(b)
}

func (c *commitWriter) Flush() {
	c.commit()
	if f, ok := c.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func (c *commitWriter) Unwrap() http.ResponseWriter { return c.ResponseWriter }

// flushBeforeResponse publishes the outbox rows a request created, and
// settles their consumers, before the first byte of its response, while the
// instance still has CPU (S-14): after every write, and after a read that
// queued rows. /internal/ routes flush inside their own settle.
func flushBeforeResponse(next http.Handler, flush func(context.Context)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/internal/") {
			next.ServeHTTP(w, r)
			return
		}
		ctx, queued := repository.WithQueued(r.Context())
		r = r.WithContext(ctx)
		safe := r.Method == http.MethodGet || r.Method == http.MethodHead || r.Method == http.MethodOptions
		cw := &commitWriter{ResponseWriter: w, before: func() {
			if safe && !queued.Any() {
				return
			}
			fctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), flushTimeout)
			defer cancel()
			flush(fctx)
		}}
		next.ServeHTTP(cw, r)
		cw.commit()
	})
}

// settler is one settle (S-14): common's consumers handle what is waiting
// (their handlers queue outbox rows), the outbox is published and its
// consumers settled, and common's consumers handle the results that
// produced, until a round publishes nothing or the budget ends.
type settler struct {
	// drain reports whether every consumer caught up within the budget.
	drain func(ctx context.Context, budget time.Duration) bool
	// flush publishes the outbox and returns how many rows it sent.
	flush  func(ctx context.Context) (int, error)
	budget time.Duration
}

// run answers whether everything was handled: a round found the lanes
// caught up and published nothing.
func (s settler) run(ctx context.Context) bool {
	ctx, cancel := context.WithTimeout(ctx, s.budget)
	defer cancel()
	for range settleRounds {
		// Half of what is left: a deep backlog must not starve the publish.
		caughtUp := s.drain(ctx, remaining(ctx)/2)
		sent, err := s.flush(ctx)
		if err != nil {
			slog.WarnContext(ctx, "outbox flush failed; the next pass retries", "step", "settle", "error", err)
			return false
		}
		if sent == 0 && caughtUp {
			return true
		}
		if ctx.Err() != nil {
			return false
		}
	}
	return false
}

func remaining(ctx context.Context) time.Duration {
	deadline, ok := ctx.Deadline()
	if !ok {
		return settleBudget
	}
	return max(time.Until(deadline), 0)
}
