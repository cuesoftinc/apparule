package repository

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

const reportCols = `r.id, r.reporter_id, ra.username, r.subject_kind, r.subject_id, r.subject_preview, r.reason, r.detail,
	r.status, r.action, r.actioned_by, ma.username, r.actioned_at, r.created_at`

const reportFrom = ` FROM report r JOIN account ra ON ra.id = r.reporter_id LEFT JOIN account ma ON ma.id = r.actioned_by`

func scanReport(r pgx.Row) (*model.Report, error) {
	var rep model.Report
	var preview []byte
	var byID, byName *string
	err := r.Scan(&rep.ID, &rep.Reporter.ID, &rep.Reporter.Username, &rep.SubjectKind, &rep.SubjectID, &preview, &rep.Reason,
		&rep.Detail, &rep.Status, &rep.Action, &byID, &byName, &rep.ActionedAt, &rep.CreatedAt)
	if err != nil {
		return nil, translate(err)
	}
	_ = json.Unmarshal(preview, &rep.SubjectPreview)
	if byID != nil {
		rep.ActionedBy = &model.Ref{ID: *byID, Username: *byName}
	}
	return &rep, nil
}

func InsertReport(ctx context.Context, tx pgx.Tx, reporterID, kind, subjectID, reason string, detail *string, preview model.ReportPreview) (*model.Report, error) {
	var id string
	if err := tx.QueryRow(ctx, `INSERT INTO report (reporter_id, subject_kind, subject_id, subject_preview, reason, detail)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, reporterID, kind, subjectID, mustJSON(preview), reason, detail).Scan(&id); err != nil {
		return nil, err
	}
	return scanReport(tx.QueryRow(ctx, `SELECT `+reportCols+reportFrom+` WHERE r.id = $1`, id))
}

// ModerationQueue lists open reports first, then actioned ones as the audit
// trail; dismissed reports leave the queue (pages.md B7a).
func ModerationQueue(ctx context.Context, tx pgx.Tx, offset, limit int) ([]model.Report, error) {
	rows, err := tx.Query(ctx, `SELECT `+reportCols+reportFrom+` WHERE r.status IN ('open', 'actioned')
		ORDER BY r.status = 'actioned', r.created_at DESC OFFSET $1 LIMIT $2`, offset, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, scanReport)
}

func GetReport(ctx context.Context, tx pgx.Tx, id string) (*model.Report, error) {
	return scanReport(tx.QueryRow(ctx, `SELECT `+reportCols+reportFrom+` WHERE r.id = $1`, id))
}

func ActOnReport(ctx context.Context, tx pgx.Tx, id, action, moderatorID string) error {
	status := "actioned"
	if action == "dismiss" {
		status = "dismissed"
	}
	_, err := tx.Exec(ctx, `UPDATE report SET status = $2, action = $3, actioned_by = $4, actioned_at = now() WHERE id = $1`,
		id, status, action, moderatorID)
	return err
}

// ReportSubject previews a reported post, comment or account.
func ReportSubject(ctx context.Context, tx pgx.Tx, kind, id string) (preview model.ReportPreview, thumbKey *string, authorID *string, err error) {
	switch kind {
	case "post":
		err = tx.QueryRow(ctx, `SELECT p.caption, a.username, d.account_id,
				(SELECT object_key FROM post_media m WHERE m.post_id = p.id ORDER BY position LIMIT 1)
			FROM post p JOIN designer_profile d ON d.id = p.designer_id JOIN account a ON a.id = d.account_id WHERE p.id::text = $1`, id).
			Scan(&preview.Text, &preview.AuthorUsername, &authorID, &thumbKey)
	case "comment":
		err = tx.QueryRow(ctx, `SELECT c.body, a.username, a.id FROM comment c JOIN account a ON a.id = c.author_id WHERE c.id::text = $1`, id).
			Scan(&preview.Text, &preview.AuthorUsername, &authorID)
	default:
		err = tx.QueryRow(ctx, `SELECT username, username, id FROM account WHERE id::text = $1 OR lower(username) = lower($1)`, id).
			Scan(&preview.Text, &preview.AuthorUsername, &authorID)
	}
	return preview, thumbKey, authorID, translate(err)
}

func HideComment(ctx context.Context, tx pgx.Tx, id string) error {
	_, err := tx.Exec(ctx, `UPDATE comment SET hidden_by_moderation = true WHERE id::text = $1`, id)
	return err
}

func SuspendAccount(ctx context.Context, tx pgx.Tx, id string) error {
	_, err := tx.Exec(ctx, `UPDATE account SET suspended_at = coalesce(suspended_at, now()) WHERE id = $1`, id)
	return err
}

// ── Instance requests (APP-002) ─────────────────────────────────────────

func InsertInstanceRequest(ctx context.Context, tx pgx.Tx, workspaceID, accountID, notes string) (*model.InstanceRequest, error) {
	var r model.InstanceRequest
	err := tx.QueryRow(ctx, `INSERT INTO instance_request (workspace_id, account_id, notes) VALUES ($1, $2, $3)
		RETURNING id, status, notes, created_at, updated_at`, workspaceID, accountID, notes).Scan(&r.ID, &r.Status, &r.Notes, &r.CreatedAt, &r.UpdatedAt)
	return &r, err
}

func ListInstanceRequests(ctx context.Context, tx pgx.Tx, workspaceID string) ([]model.InstanceRequest, error) {
	rows, err := tx.Query(ctx, `SELECT id, status, notes, created_at, updated_at FROM instance_request WHERE workspace_id = $1
		ORDER BY created_at DESC`, workspaceID)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*model.InstanceRequest, error) {
		var x model.InstanceRequest
		return &x, r.Scan(&x.ID, &x.Status, &x.Notes, &x.CreatedAt, &x.UpdatedAt)
	})
}
