// Package middleware: request id, structured logs, panic recovery, the CORS
// contract (engineering.md §CORS), and auth with the principal (§2).
package middleware

import (
	"context"
	"log/slog"
	"net/http"
	"runtime/debug"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
)

type ctxKey int

const (
	requestIDKey       ctxKey = iota
	requestLogStateKey ctxKey = 101
)

type requestLogState struct {
	accountID string
	route     string
}

// MatchedRoute copies the pattern selected by net/http.ServeMux.
func MatchedRoute(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if state, ok := r.Context().Value(requestLogStateKey).(*requestLogState); ok {
			state.route = r.Pattern
		}
		next.ServeHTTP(w, r)
	})
}

// MatchServeMuxPattern resolves a nested ServeMux route before authentication
// can terminate the request before its leaf handler runs.
func MatchServeMuxPattern(mux *http.ServeMux, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, pattern := mux.Handler(r)
		if state, ok := r.Context().Value(requestLogStateKey).(*requestLogState); ok {
			state.route = pattern
		}
		next.ServeHTTP(w, r)
	})
}

func Chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}

func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-Id")
		if id == "" || len(id) > 64 {
			id = uuid.NewString()
		}
		w.Header().Set("X-Request-Id", id)
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), requestIDKey, id)))
	})
}

type statusWriter struct {
	http.ResponseWriter
	status int
}

func (s *statusWriter) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

// Logger writes one line per request: ids and timings only, never bodies
// or query strings (the never-log list, engineering.md §5).
func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w, status: http.StatusOK}
		logState := &requestLogState{}
		ctx := context.WithValue(r.Context(), requestLogStateKey, logState)
		next.ServeHTTP(sw, r.WithContext(ctx))
		if r.URL.Path == "/health" || r.URL.Path == "/ready" {
			return
		}
		route := logState.route
		if route == "" {
			route = r.Pattern
		}
		if route == "" {
			route = r.URL.Path
		}
		attrs := []any{"method", r.Method, "path", r.URL.Path, "route", route,
			"status", sw.status, "ms", time.Since(start).Milliseconds(),
			"request_id", r.Context().Value(requestIDKey)}
		if logState.accountID != "" {
			attrs = append(attrs, "account_id", logState.accountID)
		}
		slog.Info("request", attrs...)
	})
}

func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if v := recover(); v != nil {
				slog.Error("panic", "value", v, "stack", string(debug.Stack()))
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				_, _ = w.Write([]byte(`{"error":{"code":"internal","message":"Something went wrong","details":{}}}`))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// CORS echoes the Origin only when allowlisted; credentials allowed for the session cookie.
func CORS(origins []string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			w.Header().Add("Vary", "Origin")
			if origin != "" && slices.Contains(origins, origin) {
				h := w.Header()
				h.Set("Access-Control-Allow-Origin", origin)
				h.Set("Access-Control-Allow-Credentials", "true")
				h.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
				h.Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key")
				h.Set("Access-Control-Expose-Headers", "Retry-After, X-Request-Id")
				h.Set("Access-Control-Max-Age", "600")
			}
			if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func bearer(r *http.Request) string {
	token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	if !ok {
		return ""
	}
	return strings.TrimSpace(token)
}
