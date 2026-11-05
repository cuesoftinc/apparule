package handler

import (
	"context"
	"log/slog"
	"net/http"
	"time"
)

// Settle serves POST /internal/settle: it handles everything waiting for
// this service, within a budget, and answers whether it caught up (S-14).
// Callers are Cloud Scheduler's invoker and the other services' accounts.
type Settle struct {
	Run      func(context.Context) (caughtUp bool)
	Verifier Verifier
	Audience string
	Invokers []string
}

// Guard passes only a Google ID token from one of Invokers.
func (s *Settle) Guard(next http.Handler) http.Handler {
	return guardInvokers(s.Verifier, s.Audience, s.Invokers, next)
}

// Handle runs one settle and answers {"caught_up", "ms"}.
func (s *Settle) Handle(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	caughtUp := s.Run(r.Context())
	ms := time.Since(start).Milliseconds()
	slog.InfoContext(r.Context(), "settled", "step", "settle", "caught_up", caughtUp, "ms", ms)
	writeJSON(w, http.StatusOK, map[string]any{"caught_up": caughtUp, "ms": ms})
}
