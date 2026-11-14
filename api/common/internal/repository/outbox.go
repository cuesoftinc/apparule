package repository

import (
	"context"
	"encoding/json"
	"sort"
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

// LeaseOutbox takes up to limit unsent rows whose lease is free or lapsed and
// leases them to owner for `lease`; concurrent publishers skip each other's
// rows (SKIP LOCKED) and the statement holds no lock after it returns.
func LeaseOutbox(ctx context.Context, tx pgx.Tx, limit int, lease time.Duration, owner string) ([]OutboxRow, error) {
	rows, err := tx.Query(ctx, `UPDATE outbox SET lease_until = now() + make_interval(secs => $2), lease_owner = $3
		WHERE id IN (SELECT id FROM outbox WHERE published_at IS NULL AND (lease_until IS NULL OR lease_until < now())
			ORDER BY id LIMIT $1 FOR UPDATE SKIP LOCKED)
		RETURNING id, event, message_key, request_id, payload`, limit, lease.Seconds(), owner)
	if err != nil {
		return nil, err
	}
	out, err := collect(rows, func(r pgx.Row) (*OutboxRow, error) {
		var o OutboxRow
		return &o, r.Scan(&o.ID, &o.Event, &o.Key, &o.RequestID, &o.Payload)
	})
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out, err
}

// ReleaseOutbox frees owner's lease on rows that were not sent, so the next
// pass retries them in order. Rows another pass has leased since are left alone.
func ReleaseOutbox(ctx context.Context, tx pgx.Tx, ids []int64, owner string) error {
	_, err := tx.Exec(ctx, `UPDATE outbox SET lease_until = NULL, lease_owner = NULL
		WHERE id = ANY($1) AND published_at IS NULL AND lease_owner = $2`, ids, owner)
	return err
}

// MarkPublished marks owner's rows sent; a row another pass leased after
// owner's lease lapsed is left to that pass.
func MarkPublished(ctx context.Context, tx pgx.Tx, ids []int64, owner string) error {
	_, err := tx.Exec(ctx, `UPDATE outbox SET published_at = now(), lease_until = NULL, lease_owner = NULL
		WHERE id = ANY($1) AND lease_owner = $2`, ids, owner)
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
