package repository

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// SessionRow is a measurement session with what the service layer needs
// beyond its wire shape.
type SessionRow struct {
	model.Session
	WorkspaceID string
	Template    *string
	QCCode      *string
	QCPose      *string
	Attempt     int
	Processing  *time.Time
	ResentAt    *time.Time
}

const sessionCols = `s.id, s.workspace_id, s.customer_id, s.method, s.input_height_cm::float8, s.status, s.template,
	s.qc_code, s.qc_pose, s.error_code, s.attempt, s.pipeline_meta, s.processing_since, s.resent_at, s.created_at`

func scanSession(r pgx.Row) (*SessionRow, error) {
	var s SessionRow
	var meta []byte
	err := r.Scan(&s.ID, &s.WorkspaceID, &s.CustomerID, &s.Method, &s.InputHeightCM, &s.Status, &s.Template,
		&s.QCCode, &s.QCPose, &s.ErrorCode, &s.Attempt, &meta, &s.Processing, &s.ResentAt, &s.CreatedAt)
	if err != nil {
		return nil, translate(err)
	}
	s.PipelineMeta = meta
	return &s, nil
}

// GetSession reads one session (RLS hides other workspaces' sessions).
func GetSession(ctx context.Context, tx pgx.Tx, id string) (*SessionRow, error) {
	s, err := scanSession(tx.QueryRow(ctx, `SELECT `+sessionCols+` FROM measurement_session s WHERE s.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return s, loadSessionDetails(ctx, tx, []*SessionRow{s})
}

// LockSession reads a session FOR UPDATE.
func LockSession(ctx context.Context, tx pgx.Tx, id string) (*SessionRow, error) {
	return scanSession(tx.QueryRow(ctx, `SELECT `+sessionCols+` FROM measurement_session s WHERE s.id = $1 FOR UPDATE`, id))
}

// ListSessions returns a customer's sessions, newest first. Captures still
// in flight (awaiting_upload, processing, failed_qc, failed) are not part of
// the vault's history.
func ListSessions(ctx context.Context, tx pgx.Tx, customerID string, offset, limit int) ([]*SessionRow, error) {
	rows, err := tx.Query(ctx, `SELECT `+sessionCols+` FROM measurement_session s
		WHERE s.customer_id = $1 AND s.status IN ('pending_save', 'complete')
		ORDER BY s.created_at DESC, s.id OFFSET $2 LIMIT $3`, customerID, offset, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*SessionRow
	for rows.Next() {
		s, err := scanSession(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, loadSessionDetails(ctx, tx, out)
}

func loadSessionDetails(ctx context.Context, tx pgx.Tx, sessions []*SessionRow) error {
	if len(sessions) == 0 {
		return nil
	}
	ids := make([]string, len(sessions))
	byID := map[string]*SessionRow{}
	for i, s := range sessions {
		ids[i] = s.ID
		s.Measurements = []model.Measurement{}
		byID[s.ID] = s
	}
	rows, err := tx.Query(ctx, `SELECT id, session_id, name, value_cm::float8, source, confidence::float8
		FROM measurement WHERE session_id::text = ANY($1) ORDER BY session_id, position`, ids)
	if err != nil {
		return err
	}
	ms, err := collect(rows, func(r pgx.Row) (*model.Measurement, error) {
		var m model.Measurement
		return &m, r.Scan(&m.ID, &m.SessionID, &m.Name, &m.ValueCM, &m.Source, &m.Confidence)
	})
	if err != nil {
		return err
	}
	for _, m := range ms {
		byID[m.SessionID].Measurements = append(byID[m.SessionID].Measurements, m)
	}
	rows, err = tx.Query(ctx, `SELECT session_id, pose, accepted FROM capture_asset WHERE session_id::text = ANY($1)`, ids)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var sid, pose string
		var accepted *bool
		if err := rows.Scan(&sid, &pose, &accepted); err != nil {
			return err
		}
		s := byID[sid]
		if s.Poses == nil {
			s.Poses = map[string]string{}
		}
		switch {
		case accepted == nil:
			s.Poses[pose] = "uploaded"
		case *accepted:
			s.Poses[pose] = "accepted"
		default:
			s.Poses[pose] = "failed"
		}
	}
	return rows.Err()
}

type NewSession struct {
	WorkspaceID    string
	CustomerID     string
	Method         string
	HeightCM       *float64
	Status         string
	Template       *string
	IdempotencyKey *string
}

func InsertSession(ctx context.Context, tx pgx.Tx, s NewSession) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO measurement_session (workspace_id, customer_id, method, input_height_cm, status, template, idempotency_key)
		VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
		s.WorkspaceID, s.CustomerID, s.Method, s.HeightCM, s.Status, s.Template, s.IdempotencyKey).Scan(&id)
	return id, translate(err)
}

// SessionByIdempotencyKey finds the session a retried create already made.
func SessionByIdempotencyKey(ctx context.Context, tx pgx.Tx, customerID, key string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `SELECT id FROM measurement_session WHERE customer_id = $1 AND idempotency_key = $2`, customerID, key).Scan(&id)
	return id, translate(err)
}

type MeasurementInput struct {
	Name       string
	ValueCM    float64
	Source     string
	Confidence *float64
}

// AppendMeasurements adds rows after the session's last position.
func AppendMeasurements(ctx context.Context, tx pgx.Tx, sessionID, workspaceID string, ms []MeasurementInput) error {
	var next int
	if err := tx.QueryRow(ctx, `SELECT coalesce(max(position) + 1, 0) FROM measurement WHERE session_id = $1`, sessionID).Scan(&next); err != nil {
		return err
	}
	batch := &pgx.Batch{}
	for i, m := range ms {
		batch.Queue(`INSERT INTO measurement (session_id, workspace_id, position, name, value_cm, source, confidence)
			VALUES ($1, $2, $3, $4, $5, $6, $7)`, sessionID, workspaceID, next+i, m.Name, m.ValueCM, m.Source, m.Confidence)
	}
	return tx.SendBatch(ctx, batch).Close()
}

// SessionUpdate sets a session's capture state. Nil fields are left alone.
type SessionUpdate struct {
	Status          string
	Attempt         *int
	QCCode, QCPose  *string
	ClearQC         bool
	ErrorCode       *string
	PipelineMeta    json.RawMessage
	ProcessingSince *time.Time
	ClearProcessing bool
	ResentAt        *time.Time
	Saved           bool
}

func UpdateSession(ctx context.Context, tx pgx.Tx, id string, u SessionUpdate) error {
	_, err := tx.Exec(ctx, `UPDATE measurement_session SET
			status = $2,
			attempt = coalesce($3, attempt),
			qc_code = CASE WHEN $6 THEN NULL ELSE coalesce($4, qc_code) END,
			qc_pose = CASE WHEN $6 THEN NULL ELSE coalesce($5, qc_pose) END,
			error_code = coalesce($7, error_code),
			pipeline_meta = coalesce($8, pipeline_meta),
			processing_since = CASE WHEN $10 THEN NULL ELSE coalesce($9, processing_since) END,
			resent_at = CASE WHEN $10 THEN NULL ELSE coalesce($11, resent_at) END,
			saved_at = CASE WHEN $12 THEN now() ELSE saved_at END
		WHERE id = $1`,
		id, u.Status, u.Attempt, u.QCCode, u.QCPose, u.ClearQC, u.ErrorCode, nilIfEmpty(u.PipelineMeta),
		u.ProcessingSince, u.ClearProcessing, u.ResentAt, u.Saved)
	return err
}

func DeleteSession(ctx context.Context, tx pgx.Tx, id string) error {
	tag, err := tx.Exec(ctx, `DELETE FROM measurement_session WHERE id = $1`, id)
	if err == nil && tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return err
}

// LatestCompleteSession is the vault's current session (MI-11).
func LatestCompleteSession(ctx context.Context, tx pgx.Tx, customerID string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `SELECT id FROM measurement_session WHERE customer_id = $1 AND status = 'complete'
		ORDER BY created_at DESC LIMIT 1`, customerID).Scan(&id)
	return id, translate(err)
}

// ── Capture images ──────────────────────────────────────────────────────

type Asset struct {
	ID        string
	SessionID string
	Pose      string
	Key       string
	Width     int
	Height    int
	Size      int64
	Stage     string
	Accepted  *bool
}

func ListAssets(ctx context.Context, tx pgx.Tx, sessionID string) (map[string]Asset, error) {
	rows, err := tx.Query(ctx, `SELECT id, session_id, pose, object_key, width, height, size_bytes, stage, accepted
		FROM capture_asset WHERE session_id = $1`, sessionID)
	if err != nil {
		return nil, err
	}
	list, err := collect(rows, func(r pgx.Row) (*Asset, error) {
		var a Asset
		return &a, r.Scan(&a.ID, &a.SessionID, &a.Pose, &a.Key, &a.Width, &a.Height, &a.Size, &a.Stage, &a.Accepted)
	})
	out := map[string]Asset{}
	for _, a := range list {
		out[a.Pose] = a
	}
	return out, err
}

// PutAsset records (or replaces, on a retake) a pose's uploaded image. It
// returns the key it replaced, if any, so the caller can delete it.
func PutAsset(ctx context.Context, tx pgx.Tx, sessionID, workspaceID, pose, key string, width, height int, size int64) (string, error) {
	var old *string
	err := tx.QueryRow(ctx, `SELECT object_key FROM capture_asset WHERE session_id = $1 AND pose = $2`, sessionID, pose).Scan(&old)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return "", err
	}
	_, err = tx.Exec(ctx, `INSERT INTO capture_asset (session_id, workspace_id, pose, object_key, width, height, size_bytes)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (session_id, pose) DO UPDATE SET object_key = EXCLUDED.object_key, width = EXCLUDED.width,
			height = EXCLUDED.height, size_bytes = EXCLUDED.size_bytes, stage = 'tmp', accepted = NULL`,
		sessionID, workspaceID, pose, key, width, height, size)
	if old != nil && *old != key {
		return *old, err
	}
	return "", err
}

func SetAssetVerdict(ctx context.Context, tx pgx.Tx, sessionID, pose string, accepted bool) error {
	_, err := tx.Exec(ctx, `UPDATE capture_asset SET accepted = $3 WHERE session_id = $1 AND pose = $2`, sessionID, pose, accepted)
	return err
}

func ConfirmAsset(ctx context.Context, tx pgx.Tx, id, key string, retention time.Time) error {
	_, err := tx.Exec(ctx, `UPDATE capture_asset SET object_key = $2, stage = 'confirmed', retention_until = $3 WHERE id = $1`, id, key, retention)
	return err
}

// ── Upload tickets (S-15) ───────────────────────────────────────────────

type TicketRow struct {
	JTI        string
	AccountID  string
	TargetKind string
	TargetID   string
	Poses      []string
	MaxFiles   int
	MaxBytes   int64
	ExpiresAt  time.Time
	UsedAt     *time.Time
}

func InsertTicket(ctx context.Context, tx pgx.Tx, t TicketRow) error {
	_, err := tx.Exec(ctx, `INSERT INTO upload_ticket (jti, account_id, target_kind, target_id, poses, max_files, max_bytes, expires_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, t.JTI, t.AccountID, t.TargetKind, t.TargetID, t.Poses, t.MaxFiles, t.MaxBytes, t.ExpiresAt)
	return err
}

// UseTicket marks a ticket used and returns it; a used or unknown ticket
// returns ErrNotFound (single use, S-15).
func UseTicket(ctx context.Context, tx pgx.Tx, jti string) (*TicketRow, error) {
	var t TicketRow
	err := tx.QueryRow(ctx, `UPDATE upload_ticket SET used_at = now() WHERE jti = $1 AND used_at IS NULL
		RETURNING jti, account_id, target_kind, target_id, poses, max_files, max_bytes, expires_at, used_at`, jti).
		Scan(&t.JTI, &t.AccountID, &t.TargetKind, &t.TargetID, &t.Poses, &t.MaxFiles, &t.MaxBytes, &t.ExpiresAt, &t.UsedAt)
	return &t, translate(err)
}

// UploadedBytesToday sums an account's stored upload bytes since midnight
// UTC, for the 100 MB/day quota (§8).
func UploadedBytesToday(ctx context.Context, tx pgx.Tx, accountID string) (int64, error) {
	var n int64
	err := tx.QueryRow(ctx, `SELECT
		coalesce((SELECT sum(a.size_bytes) FROM capture_asset a JOIN measurement_session s ON s.id = a.session_id
			JOIN customer c ON c.id = s.customer_id WHERE c.account_id = $1 AND a.created_at >= date_trunc('day', now())), 0) +
		coalesce((SELECT sum(size_bytes) FROM media WHERE account_id = $1 AND created_at >= date_trunc('day', now())), 0)`, accountID).Scan(&n)
	return n, err
}

// ── Exports ─────────────────────────────────────────────────────────────

func InsertExport(ctx context.Context, tx pgx.Tx, sessionID, workspaceID, format, key string) error {
	_, err := tx.Exec(ctx, `INSERT INTO session_export (session_id, workspace_id, format, object_key) VALUES ($1, $2, $3, $4)`,
		sessionID, workspaceID, format, key)
	return err
}

// ── Customers ───────────────────────────────────────────────────────────

func CustomerTemplate(ctx context.Context, tx pgx.Tx, customerID string) (*string, error) {
	var t *string
	err := tx.QueryRow(ctx, `SELECT measurement_template FROM customer WHERE id = $1`, customerID).Scan(&t)
	return t, translate(err)
}

// HasConsent reports whether the account accepted both documents (flows/
// vault.md: consent is required before the first session persists).
func HasConsent(ctx context.Context, tx pgx.Tx, accountID string) (bool, error) {
	var n int
	err := tx.QueryRow(ctx, `SELECT count(DISTINCT document) FROM consent_record WHERE account_id = $1 AND document IN ('tos', 'privacy')`,
		accountID).Scan(&n)
	return n == 2, err
}

func nilIfEmpty(raw json.RawMessage) []byte {
	if len(raw) == 0 {
		return nil
	}
	return raw
}
