package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"
)

// Enqueue writes an event in the caller's transaction (§6.6): it is sent
// if and only if the business write commits.
func Enqueue(ctx context.Context, tx pgx.Tx, event, key string, data any) error {
	_, err := tx.Exec(ctx, `INSERT INTO outbox (event, message_key, payload) VALUES ($1, $2, $3)`, event, key, mustJSON(data))
	return err
}

type OutboxRow struct {
	ID      int64
	Event   string
	Key     string
	Payload json.RawMessage
}

// ClaimOutbox locks up to limit unsent rows; concurrent publishers skip
// each other's rows (SKIP LOCKED).
func ClaimOutbox(ctx context.Context, tx pgx.Tx, limit int) ([]OutboxRow, error) {
	rows, err := tx.Query(ctx, `SELECT id, event, message_key, payload FROM outbox WHERE published_at IS NULL
		ORDER BY id LIMIT $1 FOR UPDATE SKIP LOCKED`, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*OutboxRow, error) {
		var o OutboxRow
		return &o, r.Scan(&o.ID, &o.Event, &o.Key, &o.Payload)
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

// PendingOutbox counts unsent rows per event, for the sweep's wake-ups.
func PendingOutbox(ctx context.Context, tx pgx.Tx) (map[string]int, error) {
	rows, err := tx.Query(ctx, `SELECT event, count(*) FROM outbox WHERE published_at IS NULL GROUP BY event`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]int{}
	for rows.Next() {
		var event string
		var n int
		if err := rows.Scan(&event, &n); err != nil {
			return nil, err
		}
		out[event] = n
	}
	return out, rows.Err()
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
