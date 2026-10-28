package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const principalKey ctxKey = 100

func PrincipalFrom(ctx context.Context) *repository.Principal {
	p, _ := ctx.Value(principalKey).(*repository.Principal)
	return p
}

func WithPrincipal(ctx context.Context, p *repository.Principal) context.Context {
	return context.WithValue(ctx, principalKey, p)
}

// Sessions is the slice of the account service auth needs.
type Sessions interface {
	ResolveSession(ctx context.Context, claims *auth.Claims) (*repository.Principal, error)
}

// Authenticate verifies the API's own session token (bearer header, else the
// session cookie), checks it against the account's session epoch, and
// resolves the principal once per request (engineering.md §2).
func Authenticate(cfg *config.Config, sessions Sessions) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := bearer(r)
			if token == "" {
				cookie, err := r.Cookie(cfg.Auth.SessionCookieName)
				if err != nil || cookie.Value == "" {
					deny(w, http.StatusUnauthorized, "unauthenticated", "Sign in to continue")
					return
				}
				if !CookieRequestAllowed(cfg, r) {
					deny(w, http.StatusForbidden, "csrf_rejected", "This request is not allowed")
					return
				}
				token = cookie.Value
			}
			claims, err := auth.ParseToken(cfg.Auth.JWTSecret, token)
			switch {
			case errors.Is(err, auth.ErrExpired):
				deny(w, http.StatusUnauthorized, "token_expired", "Your session expired; sign in again")
				return
			case err != nil:
				deny(w, http.StatusUnauthorized, "unauthenticated", "Sign in to continue")
				return
			}
			p, err := sessions.ResolveSession(r.Context(), claims)
			switch {
			case errors.Is(err, auth.ErrSessionInvalid):
				deny(w, http.StatusUnauthorized, "unauthenticated", "Sign in to continue")
				return
			case err != nil:
				deny(w, http.StatusServiceUnavailable, "session_unavailable", "Sessions are temporarily unavailable")
				return
			}
			if p.Suspended {
				deny(w, http.StatusForbidden, "account_disabled", "This account has been disabled")
				return
			}
			next.ServeHTTP(w, r.WithContext(WithPrincipal(r.Context(), p)))
		})
	}
}

// CookieRequestAllowed guards cookie-authenticated requests: a present Origin
// must be the web app exactly, and Fetch Metadata must be same-origin or
// same-site. Without an Origin only same-origin vouches, since same-site alone
// would admit sibling subdomains.
func CookieRequestAllowed(cfg *config.Config, r *http.Request) bool {
	origin := strings.TrimRight(strings.TrimSpace(r.Header.Get("Origin")), "/")
	if origin != "" && origin != cfg.WebURL {
		return false
	}
	switch strings.ToLower(strings.TrimSpace(r.Header.Get("Sec-Fetch-Site"))) {
	case "", "same-origin", "same-site":
	default:
		return false
	}
	return origin != "" || strings.EqualFold(strings.TrimSpace(r.Header.Get("Sec-Fetch-Site")), "same-origin")
}

func deny(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write([]byte(`{"error":{"code":"` + code + `","message":"` + message + `","details":{}}}`))
}
