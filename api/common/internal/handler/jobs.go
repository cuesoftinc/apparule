package handler

import (
	"context"
	"log/slog"
	"net/http"
	"slices"
	"strings"
	"time"

	"google.golang.org/api/idtoken"
)

// Verifier checks a Google OIDC token for audience and returns its claims.
type Verifier interface {
	Verify(ctx context.Context, token, audience string) (Claims, error)
}

// Claims are the token claims the guard reads.
type Claims struct {
	Email         string
	EmailVerified bool
}

type googleVerifier struct{}

func NewGoogleVerifier() Verifier { return googleVerifier{} }

func (googleVerifier) Verify(ctx context.Context, token, audience string) (Claims, error) {
	p, err := idtoken.Validate(ctx, token, audience)
	if err != nil {
		return Claims{}, err
	}
	email, _ := p.Claims["email"].(string)
	verified, _ := p.Claims["email_verified"].(bool)
	return Claims{Email: email, EmailVerified: verified}, nil
}

// Jobs serves POST /internal/jobs/{name} for Cloud Scheduler.
type Jobs struct {
	Run      map[string]func(context.Context) error
	Verifier Verifier
	Audience string
	Invoker  string
}

// Guard passes only the scheduler's invoker: unset configuration fails closed.
func (j *Jobs) Guard(next http.Handler) http.Handler {
	return guardInvokers(j.Verifier, j.Audience, []string{j.Invoker}, next)
}

// guardInvokers passes only a verified Google ID token for audience whose
// email is one of invokers; with no audience or no invoker it fails closed.
func guardInvokers(verifier Verifier, audience string, invokers []string, next http.Handler) http.Handler {
	var allowed []string
	for _, email := range invokers {
		if email != "" {
			allowed = append(allowed, email)
		}
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if audience == "" || len(allowed) == 0 {
			slog.ErrorContext(r.Context(), "internal auth not configured")
			writeError(w, http.StatusServiceUnavailable, "unavailable", "Internal auth is not configured", nil)
			return
		}
		scheme, token, _ := strings.Cut(strings.TrimSpace(r.Header.Get("Authorization")), " ")
		token = strings.TrimSpace(token)
		if !strings.EqualFold(scheme, "Bearer") || token == "" {
			writeError(w, http.StatusUnauthorized, "unauthorized", "Missing bearer token", nil)
			return
		}
		claims, err := verifier.Verify(r.Context(), token, audience)
		if err != nil {
			slog.WarnContext(r.Context(), "internal token rejected", "error", err)
			writeError(w, http.StatusUnauthorized, "unauthorized", "Invalid token", nil)
			return
		}
		if !claims.EmailVerified || !slices.Contains(allowed, claims.Email) {
			slog.WarnContext(r.Context(), "internal token rejected: caller is not an invoker")
			writeError(w, http.StatusForbidden, "forbidden", "Caller is not allowed", nil)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// Handle runs the named job and answers {"job", "ms"}.
func (j *Jobs) Handle(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	run := j.Run[name]
	if run == nil {
		writeError(w, http.StatusNotFound, "not_found", "Not found", nil)
		return
	}
	start := time.Now()
	if err := run(r.Context()); err != nil {
		slog.ErrorContext(r.Context(), "job failed", "job", name, "error", err)
		writeError(w, http.StatusInternalServerError, "internal", "Something went wrong", nil)
		return
	}
	ms := time.Since(start).Milliseconds()
	slog.InfoContext(r.Context(), "job done", "job", name, "ms", ms)
	writeJSON(w, http.StatusOK, map[string]any{"job": name, "ms": ms})
}
