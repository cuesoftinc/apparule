package repository

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

func InsertMediaBatch(ctx context.Context, tx pgx.Tx, accountID, kind string, requestID *string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO media_batch (account_id, kind, request_id) VALUES ($1, $2, $3) RETURNING id`,
		accountID, kind, requestID).Scan(&id)
	return id, err
}

type MediaRow struct {
	ID        string
	BatchID   string
	AccountID string
	Kind      string
	Position  int
	Key       string
	Width     int
	Height    int
	Size      int64
	Stage     string
	RequestID *string
}

type BatchRow struct {
	ID        string
	AccountID string
	Kind      string
	RequestID *string
	Status    string
	Items     []MediaRow
}

func GetMediaBatch(ctx context.Context, tx pgx.Tx, id string) (*BatchRow, error) {
	var b BatchRow
	err := tx.QueryRow(ctx, `SELECT id, account_id, kind, request_id, status FROM media_batch WHERE id = $1`, id).
		Scan(&b.ID, &b.AccountID, &b.Kind, &b.RequestID, &b.Status)
	if err != nil {
		return nil, translate(err)
	}
	rows, err := tx.Query(ctx, `SELECT m.id, m.batch_id, m.account_id, m.kind, m.position, m.object_key, m.width, m.height,
			m.size_bytes, m.stage, NULL::uuid FROM media m WHERE m.batch_id = $1 ORDER BY m.position`, id)
	if err != nil {
		return nil, err
	}
	b.Items, err = collect(rows, scanMedia)
	return &b, err
}

func scanMedia(r pgx.Row) (*MediaRow, error) {
	var m MediaRow
	return &m, r.Scan(&m.ID, &m.BatchID, &m.AccountID, &m.Kind, &m.Position, &m.Key, &m.Width, &m.Height, &m.Size, &m.Stage, &m.RequestID)
}

// GetMedia reads media rows by id, with the order their batch belongs to.
func GetMedia(ctx context.Context, tx pgx.Tx, ids []string) ([]MediaRow, error) {
	rows, err := tx.Query(ctx, `SELECT m.id, m.batch_id, m.account_id, m.kind, m.position, m.object_key, m.width, m.height,
			m.size_bytes, m.stage, b.request_id
		FROM media m JOIN media_batch b ON b.id = m.batch_id WHERE m.id::text = ANY($1)`, ids)
	if err != nil {
		return nil, err
	}
	return collect(rows, scanMedia)
}

// FillMediaBatch stores a batch's uploaded images (media.uploaded) and
// marks it ready. A batch already filled is left alone.
func FillMediaBatch(ctx context.Context, tx pgx.Tx, batchID string, images []MediaRow) (bool, error) {
	tag, err := tx.Exec(ctx, `UPDATE media_batch SET status = 'ready' WHERE id = $1 AND status = 'awaiting_upload'`, batchID)
	if err != nil || tag.RowsAffected() == 0 {
		return false, err
	}
	for i, m := range images {
		if _, err := tx.Exec(ctx, `INSERT INTO media (batch_id, account_id, kind, position, object_key, width, height, size_bytes)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, batchID, m.AccountID, m.Kind, i, m.Key, m.Width, m.Height, m.Size); err != nil {
			return false, err
		}
	}
	return true, nil
}

func ConfirmMedia(ctx context.Context, tx pgx.Tx, id, key string) error {
	_, err := tx.Exec(ctx, `UPDATE media SET object_key = $2, stage = 'confirmed' WHERE id = $1`, id, key)
	return err
}

// StaleMedia lists unused uploads older than age, for cleanup.
func StaleMedia(ctx context.Context, tx pgx.Tx, age time.Duration) ([]string, error) {
	return ids(ctx, tx, `SELECT id::text FROM media_batch WHERE created_at < now() - make_interval(secs => $1)
		AND NOT EXISTS (SELECT 1 FROM media m WHERE m.batch_id = media_batch.id AND m.stage = 'confirmed')`, age.Seconds())
}

func DeleteMediaBatches(ctx context.Context, tx pgx.Tx, batchIDs []string) error {
	_, err := tx.Exec(ctx, `DELETE FROM media_batch WHERE id::text = ANY($1)`, batchIDs)
	return err
}
