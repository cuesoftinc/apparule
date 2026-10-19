// Package service holds the CRUD rules: authorization, lookups, writes and
// hand-offs (system-design.md §4). Every decision about images belongs to
// segmentation and every money decision to commerce; services here store
// what they return.
package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
	"github.com/cuesoftinc/apparule/api/common/internal/ticket"
)

// Error is a client-facing error with a stable code (engineering.md §1).
type Error struct {
	Status     int
	Code       string
	Message    string
	Details    map[string]any
	RetryAfter time.Duration
}

func (e *Error) Error() string { return fmt.Sprintf("%d %s: %s", e.Status, e.Code, e.Message) }

func newErr(status int, code, message string) *Error {
	return &Error{Status: status, Code: code, Message: message}
}

var (
	ErrForbidden = newErr(http.StatusForbidden, "forbidden", "You can't do that")
	ErrNotFound  = newErr(http.StatusNotFound, "not_found", "Not found")
)

func invalid(message string) *Error {
	return newErr(http.StatusUnprocessableEntity, "validation_failed", message)
}

func conflict(code, message string) *Error { return newErr(http.StatusConflict, code, message) }

func rateLimited(wait time.Duration, message string) *Error {
	return &Error{Status: http.StatusTooManyRequests, Code: "rate_limited", Message: message, RetryAfter: wait}
}

// Principal is the authenticated caller.
type Principal = repository.Principal

// Services is every domain service, sharing one set of dependencies.
type Services struct {
	DB      *repository.DB
	Store   storage.Store
	Tickets *ticket.Signer
	Limiter *ratelimit.Limiter
	Config  *config.Config
	Now     func() time.Time
}

// mediaURL serves published post images from the public media/ prefix.
func (s *Services) mediaURL(key string) string { return s.Store.PublicURL(key) }

// as runs fn as the caller (row-level security on).
func (s *Services) as(ctx context.Context, p *Principal, fn func(pgx.Tx) error) error {
	return s.DB.AsAccount(ctx, p.AccountID, fn)
}

// take applies rate-limit rules for the caller.
func (s *Services) take(ctx context.Context, p *Principal, rules ...ratelimit.Rule) error {
	if ok, wait := s.Limiter.Take(ctx, p.AccountID, 1, rules...); !ok {
		return rateLimited(wait, "Too many requests; try again shortly")
	}
	return nil
}

// active blocks social and commerce actions for accounts on their way out
// (flows/auth.md §4).
func active(p *Principal) error {
	if p.DeletionPending {
		return newErr(http.StatusForbidden, "account_disabled", "This account is being deleted")
	}
	return nil
}

// Idempotent replays a stored response for (scope, key) or runs fn and
// stores its result (api.md §4). Same key with a different payload is 409.
func Idempotent[T any](ctx context.Context, s *Services, p *Principal, scope, key string, payload any, fn func() (T, error)) (T, error) {
	var zero T
	if key == "" {
		return fn()
	}
	raw, _ := json.Marshal(payload)
	sum := sha256.Sum256(raw)
	hash := hex.EncodeToString(sum[:])
	var replay *repository.Replay
	if err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		replay, err = repository.FindIdempotent(ctx, tx, p.AccountID, scope, key)
		return err
	}); err != nil {
		return zero, err
	}
	if replay != nil {
		if replay.PayloadHash != hash {
			return zero, conflict("idempotency_conflict", "Idempotency key reused with a different payload")
		}
		var out T
		return out, json.Unmarshal(replay.Response, &out)
	}
	out, err := fn()
	if err != nil {
		return zero, err
	}
	// A concurrent duplicate loses on the primary key and still returns its
	// own (identical) result.
	_ = s.as(ctx, p, func(tx pgx.Tx) error {
		return repository.SaveIdempotent(ctx, tx, p.AccountID, scope, key, hash, http.StatusOK, out)
	})
	return out, nil
}

// paging reads ?cursor= and ?limit= (api.md §4: default 50, max 100). The
// cursor is an opaque offset for unranked lists.
type Paging struct {
	Offset int
	Limit  int
}

func page[T any](items []T, p Paging) (out struct {
	Items      []T     `json:"items"`
	NextCursor *string `json:"next_cursor"`
}) {
	if items == nil {
		items = []T{}
	}
	if len(items) > p.Limit {
		items = items[:p.Limit]
		next := encodeOffset(p.Offset + p.Limit)
		out.NextCursor = &next
	}
	out.Items = items
	return out
}
