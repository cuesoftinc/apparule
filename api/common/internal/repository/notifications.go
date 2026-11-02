package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// VisibleKinds are the activity-sheet rows (design.md §8.2b). Other kinds
// (capture results) exist only to drive a push.
var VisibleKinds = []string{"like", "follow", "comment", "quote", "status_change", "payout"}

type NewNotification struct {
	AccountID  string
	Kind       string
	PayloadRef string
	Text       string
	Actor      *model.Actor
	ThumbKey   *string
}

func InsertNotification(ctx context.Context, tx pgx.Tx, n NewNotification) (string, time.Time, error) {
	var id string
	var at time.Time
	err := tx.QueryRow(ctx, `INSERT INTO notification (account_id, kind, payload_ref, text, actor, thumb_key)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at`,
		n.AccountID, n.Kind, n.PayloadRef, n.Text, jsonOrNil(n.Actor), n.ThumbKey).Scan(&id, &at)
	return id, at, err
}

func ListNotifications(ctx context.Context, tx pgx.Tx, accountID string, offset, limit int) ([]model.Notification, error) {
	rows, err := tx.Query(ctx, `SELECT id, account_id, kind, payload_ref, text, actor, thumb_key, read_at, created_at
		FROM notification WHERE account_id = $1 AND kind = ANY($2)
		ORDER BY created_at DESC, id OFFSET $3 LIMIT $4`, accountID, VisibleKinds, offset, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*model.Notification, error) {
		var n model.Notification
		var actor []byte
		if err := r.Scan(&n.ID, &n.AccountID, &n.Kind, &n.PayloadRef, &n.Text, &actor, &n.ThumbKey, &n.ReadAt, &n.CreatedAt); err != nil {
			return nil, err
		}
		if len(actor) > 0 {
			n.Actor = &model.Actor{}
			_ = json.Unmarshal(actor, n.Actor)
		}
		return &n, nil
	})
}

// MarkRead marks the caller's notifications read: all of them, or ids.
func MarkRead(ctx context.Context, tx pgx.Tx, accountID string, ids []string) error {
	if len(ids) == 0 {
		_, err := tx.Exec(ctx, `UPDATE notification SET read_at = now() WHERE account_id = $1 AND read_at IS NULL`, accountID)
		return err
	}
	_, err := tx.Exec(ctx, `UPDATE notification SET read_at = now() WHERE account_id = $1 AND read_at IS NULL AND id::text = ANY($2)`, accountID, ids)
	return err
}

func PruneNotifications(ctx context.Context, tx pgx.Tx, olderThan time.Duration) (int64, error) {
	tag, err := tx.Exec(ctx, `DELETE FROM notification WHERE created_at < now() - make_interval(secs => $1)`, olderThan.Seconds())
	return tag.RowsAffected(), err
}
