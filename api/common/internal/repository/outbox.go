package repository

import (
	"context"
	"encoding/json"
	"sync/atomic"
	"time"

	"github.com/jackc/pgx/v5"
)

type queuedKey struct{}

// Queued counts the outbox rows one request queued; the server publishes
// them before it answers (S-14).
type Queued struct{ n atomic.Int64 }

func (q *Queued) Any() bool { return q.n.Load() > 0 }

// WithQueued returns a context whose Enqueue calls count on the Queued.
func WithQueued(ctx context.Context) (context.Context, *Queued) {
	q := &Queued{}
	return context.WithValue(ctx, queuedKey{}, q), q
}

// NoteQueued counts one queued row against ctx's Queued, if it has one.
func NoteQueued(ctx context.Context) {
	if q, ok := ctx.Value(queuedKey{}).(*Queued); ok {
		q.n.Add(1)
	}
}

// Enqueue writes an event in the caller's transaction (§6.6): it is sent
// if and only if the business write commits. The row gets a new request_id.
func Enqueue(ctx context.Context, tx pgx.Tx, event, key string, data any) error {
	return EnqueueRequest(ctx, tx, event, key, "", data)
}

// EnqueueRequest is Enqueue with the request_id a re-send must keep; empty
// means a new one.
func EnqueueRequest(ctx context.Context, tx pgx.Tx, event, key, requestID string, data any) error {
	NoteQueued(ctx)
	_, err := tx.Exec(ctx, `INSERT INTO outbox (event, message_key, payload, request_id)
		VALUES ($1, $2, $3, coalesce(nullif($4, ''), gen_random_uuid()::text))`, event, key, mustJSON(data), requestID)
	return err
}

type OutboxRow struct {
	ID        int64
	Event     string
	Key       string
	RequestID string
	Payload   json.RawMessage
}

// ClaimOutbox locks up to limit unsent rows; concurrent publishers skip
// each other's rows (SKIP LOCKED).
func ClaimOutbox(ctx context.Context, tx pgx.Tx, limit int) ([]OutboxRow, error) {
	rows, err := tx.Query(ctx, `SELECT id, event, message_key, request_id, payload FROM outbox WHERE published_at IS NULL
		ORDER BY id LIMIT $1 FOR UPDATE SKIP LOCKED`, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*OutboxRow, error) {
		var o OutboxRow
		return &o, r.Scan(&o.ID, &o.Event, &o.Key, &o.RequestID, &o.Payload)
	})
}

func MarkPublished(ctx context.Context, tx pgx.Tx, ids []int64) error {
	_, err := tx.Exec(ctx, `UPDATE outbox SET published_at = now() WHERE id = ANY($1)`, ids)
	return err
}

func PruneOutbox(ctx context.Context, tx pgx.Tx, olderThan time.Duration) (int64, error) {
	tag, err := tx.Exec(ctx, `DELETE FROM outbox WHERE published_at < now() - make_interval(secs => $1)`, olderThan.Seconds())
	return tag.RowsAffected(), err
}

// ClaimResult reports whether this is the first result for requestID
// (shared-messaging.md rule 9); it is claimed in the caller's transaction.
func ClaimResult(ctx context.Context, tx pgx.Tx, requestID, event string) (bool, error) {
	tag, err := tx.Exec(ctx, `INSERT INTO result_claim (request_id, event) VALUES ($1, $2) ON CONFLICT DO NOTHING`, requestID, event)
	return tag.RowsAffected() > 0, err
}

// ── Idempotency (api.md §4) ─────────────────────────────────────────────

type Replay struct {
	PayloadHash string
	Status      int
	Response    json.RawMessage
}

// FindIdempotent returns the stored response for a key, or nil.
func FindIdempotent(ctx context.Context, tx pgx.Tx, accountID, scope, key string) (*Replay, error) {
	var r Replay
	err := tx.QueryRow(ctx, `SELECT payload_hash, status, response FROM idempotency_key
		WHERE account_id = $1 AND scope = $2 AND key = $3`, accountID, scope, key).Scan(&r.PayloadHash, &r.Status, &r.Response)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	return &r, err
}

func SaveIdempotent(ctx context.Context, tx pgx.Tx, accountID, scope, key, hash string, status int, response any) error {
	_, err := tx.Exec(ctx, `INSERT INTO idempotency_key (account_id, scope, key, payload_hash, status, response)
		VALUES ($1, $2, $3, $4, $5, $6)`, accountID, scope, key, hash, status, mustJSON(response))
	return translate(err)
}

func PruneIdempotency(ctx context.Context, tx pgx.Tx, olderThan time.Duration) (int64, error) {
	tag, err := tx.Exec(ctx, `DELETE FROM idempotency_key WHERE created_at < now() - make_interval(secs => $1)`, olderThan.Seconds())
	return tag.RowsAffected(), err
}
