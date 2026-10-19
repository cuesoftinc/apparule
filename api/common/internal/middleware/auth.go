package middleware

import (
	"context"
	"errors"
	"net/http"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
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

// Accounts is the slice of the account service auth needs.
type Accounts interface {
	SignIn(ctx context.Context, id *auth.Identity) (*repository.Principal, error)
}

type Verifier interface {
	Verify(ctx context.Context, raw string) (*auth.Identity, error)
}

// Authenticate verifies the Firebase ID token (X-1: Google only), signs the
// caller in (creating the account on first sign-in), and resolves the
// principal once per request (engineering.md §2).
func Authenticate(v Verifier, accounts Accounts) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := bearer(r)
			if token == "" {
				deny(w, http.StatusUnauthorized, "unauthenticated", "Sign in to continue")
				return
			}
			id, err := v.Verify(r.Context(), token)
			switch {
			case errors.Is(err, auth.ErrExpired):
				deny(w, http.StatusUnauthorized, "token_expired", "Your session expired; sign in again")
				return
			case errors.Is(err, auth.ErrProvider):
				// flows/auth.md §4: a token from any other provider.
				deny(w, http.StatusForbidden, "provider_not_allowed", "Only Google sign-in is supported")
				return
			case err != nil:
				deny(w, http.StatusUnauthorized, "unauthenticated", "Sign in to continue")
				return
			}
			p, err := accounts.SignIn(r.Context(), id)
			if err != nil {
				deny(w, http.StatusInternalServerError, "internal", "Something went wrong")
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

func deny(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write([]byte(`{"error":{"code":"` + code + `","message":"` + message + `","details":{}}}`))
}
