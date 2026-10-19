package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
	"github.com/cuesoftinc/apparule/api/common/internal/ticket"
)

// CaptureRetention is how long saved capture images are kept (flows/vault.md §1).
const CaptureRetention = 30 * 24 * time.Hour

var poses = []string{"front", "side"}

// view turns a stored session into its wire shape, with QC copy.
func view(s *repository.SessionRow) model.Session {
	out := s.Session
	if len(out.PipelineMeta) == 0 {
		out.PipelineMeta = json.RawMessage(`{}`)
	}
	if out.Measurements == nil {
		out.Measurements = []model.Measurement{}
	}
	if s.Status == "failed_qc" && s.QCCode != nil && s.QCPose != nil {
		copyText := qcCopy(*s.QCCode, *s.QCPose)
		out.QC = &model.QCFailure{Code: *s.QCCode, Pose: *s.QCPose, Message: copyText, Guidance: copyText}
	}
	return out
}

// Sessions lists the vault (data-model.md §6.1: the self customer's sessions).
func (s *Services) Sessions(ctx context.Context, p *Principal, pg Paging) (any, error) {
	var list []model.Session
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		rows, err := repository.ListSessions(ctx, tx, p.SelfCustomerID, pg.Offset, pg.Limit+1)
		for _, r := range rows {
			list = append(list, view(r))
		}
		return err
	})
	return page(list, pg), err
}

func (s *Services) Session(ctx context.Context, p *Principal, id string) (*model.Session, error) {
	var out model.Session
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		row, err := repository.GetSession(ctx, tx, id)
		if err != nil {
			return err
		}
		out = view(row)
		return nil
	})
	return &out, err
}

type ManualInput struct {
	Name    string  `json:"name"`
	ValueCM float64 `json:"value_cm"`
}

func (s *Services) requireConsent(ctx context.Context, tx pgx.Tx, p *Principal) error {
	ok, err := repository.HasConsent(ctx, tx, p.AccountID)
	if err != nil {
		return err
	}
	if !ok {
		return newErr(http.StatusForbidden, "consent_required", "Accept the terms and privacy policy first")
	}
	return nil
}

func validMeasurements(ms []ManualInput) error {
	if len(ms) == 0 {
		return invalid("At least one measurement is required")
	}
	for _, m := range ms {
		if !nameRe.MatchString(m.Name) {
			return invalid("Measurement names are snake_case")
		}
		// flows/vault.md §2: 10-200 cm; the advisory ranges are client-side.
		if m.ValueCM < 10 || m.ValueCM > 200 || math.IsNaN(m.ValueCM) {
			return invalid("Values must be 10-200 cm")
		}
	}
	return nil
}

// CreateManualSession stores tape values (MI-13): complete at once, no height.
func (s *Services) CreateManualSession(ctx context.Context, p *Principal, ms []ManualInput, key string) (*model.Session, error) {
	if err := validMeasurements(ms); err != nil {
		return nil, err
	}
	var out model.Session
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if err := s.requireConsent(ctx, tx, p); err != nil {
			return err
		}
		if key != "" {
			if id, err := repository.SessionByIdempotencyKey(ctx, tx, p.SelfCustomerID, key); err == nil {
				row, err := repository.GetSession(ctx, tx, id)
				if err == nil {
					out = view(row)
				}
				return err
			}
		}
		id, err := repository.InsertSession(ctx, tx, repository.NewSession{
			WorkspaceID: p.WorkspaceID, CustomerID: p.SelfCustomerID, Method: "manual", Status: "complete", IdempotencyKey: optional(key),
		})
		if err != nil {
			return err
		}
		inputs := make([]repository.MeasurementInput, len(ms))
		for i, m := range ms {
			inputs[i] = repository.MeasurementInput{Name: m.Name, ValueCM: round1(m.ValueCM), Source: "pipeline"}
		}
		if err := repository.AppendMeasurements(ctx, tx, id, p.WorkspaceID, inputs); err != nil {
			return err
		}
		row, err := repository.GetSession(ctx, tx, id)
		if err == nil {
			out = view(row)
		}
		return err
	})
	return &out, err
}

// CreateCapture creates a session awaiting its photos and returns the
// upload ticket for both poses (system-design.md §6.1). Everything is
// authorized here, before a byte is stored: consent, template, account
// state, rate limits and the daily upload quota.
func (s *Services) CreateCapture(ctx context.Context, p *Principal, heightCM float64, key string) (*model.CaptureStarted, error) {
	if math.IsNaN(heightCM) || heightCM < 100 || heightCM > 230 {
		return nil, invalid("Height must be 100-230 cm")
	}
	if err := active(p); err != nil {
		return nil, err
	}
	var out model.CaptureStarted
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if err := s.requireConsent(ctx, tx, p); err != nil {
			return err
		}
		template, err := repository.CustomerTemplate(ctx, tx, p.SelfCustomerID)
		if err != nil {
			return err
		}
		if template == nil {
			// A-10b: no template, no measuring (the mock's template gate).
			return conflict("template_required", "Choose a measurement set first")
		}
		if key != "" {
			if id, err := repository.SessionByIdempotencyKey(ctx, tx, p.SelfCustomerID, key); err == nil {
				// A retried create returns the same session and a fresh ticket.
				return s.captureTicket(ctx, tx, p, id, poses, &out)
			}
		}
		if err := s.take(ctx, p,
			ratelimit.Rule{Name: "capture-min", Max: int64(s.Config.Limits.CapturesPerMin), Window: time.Minute},
			ratelimit.Rule{Name: "capture-day", Max: int64(s.Config.Limits.CapturesPerDay), Window: 24 * time.Hour}); err != nil {
			return err
		}
		if err := s.checkQuota(ctx, tx, p); err != nil {
			return err
		}
		h := round1(heightCM)
		id, err := repository.InsertSession(ctx, tx, repository.NewSession{
			WorkspaceID: p.WorkspaceID, CustomerID: p.SelfCustomerID, Method: "mediapipe_2d_v2", HeightCM: &h,
			Status: "awaiting_upload", Template: template, IdempotencyKey: optional(key),
		})
		if err != nil {
			return err
		}
		return s.captureTicket(ctx, tx, p, id, poses, &out)
	})
	return &out, err
}

// RetakeTicket issues a ticket for one pose of a failed_qc session; the
// accepted pose is kept (flows/vault.md §1).
func (s *Services) RetakeTicket(ctx context.Context, p *Principal, sessionID, pose string) (*model.CaptureStarted, error) {
	if pose != "front" && pose != "side" {
		return nil, ErrNotFound
	}
	var out model.CaptureStarted
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		row, err := repository.GetSession(ctx, tx, sessionID)
		if err != nil {
			return err
		}
		if row.Status != "failed_qc" {
			return conflict("invalid_transition", "Only a capture that failed its check can be retaken by pose")
		}
		if row.Poses[pose] == "accepted" {
			return conflict("pose_accepted", "That pose was accepted; retake the other one")
		}
		if err := s.checkQuota(ctx, tx, p); err != nil {
			return err
		}
		return s.captureTicket(ctx, tx, p, sessionID, []string{pose}, &out)
	})
	return &out, err
}

func (s *Services) checkQuota(ctx context.Context, tx pgx.Tx, p *Principal) error {
	used, err := repository.UploadedBytesToday(ctx, tx, p.AccountID)
	if err != nil {
		return err
	}
	if used >= s.Config.Limits.UploadBytesDay {
		return rateLimited(time.Until(time.Now().UTC().Truncate(24*time.Hour).Add(24*time.Hour)), "Daily upload limit reached")
	}
	return nil
}

func (s *Services) captureTicket(ctx context.Context, tx pgx.Tx, p *Principal, sessionID string, allowed []string, out *model.CaptureStarted) error {
	upload, err := s.issueTicket(ctx, tx, ticket.Request{
		AccountID: p.AccountID, Target: ticket.Target{Kind: "capture", ID: sessionID}, Poses: allowed,
		MaxFiles: len(allowed), MaxBytes: s.Config.Limits.ImageMaxBytes,
	})
	if err != nil {
		return err
	}
	row, err := repository.GetSession(ctx, tx, sessionID)
	if err != nil {
		return err
	}
	*out = model.CaptureStarted{Session: view(row), Upload: *upload}
	return nil
}

// issueTicket signs a ticket and records it (single use, S-15). Recording
// needs the bypass: tickets are a system table.
func (s *Services) issueTicket(ctx context.Context, tx pgx.Tx, r ticket.Request) (*model.UploadTicket, error) {
	raw, claims := s.Tickets.Issue(r, s.Now())
	expires := time.Unix(claims.EXP, 0).UTC()
	err := repository.Bypass(ctx, tx, func() error {
		return repository.InsertTicket(ctx, tx, repository.TicketRow{
			JTI: claims.JTI, AccountID: r.AccountID, TargetKind: r.Target.Kind, TargetID: r.Target.ID,
			Poses: nonNil(r.Poses), MaxFiles: r.MaxFiles, MaxBytes: r.MaxBytes, ExpiresAt: expires,
		})
	})
	if err != nil {
		return nil, err
	}
	fields := []string{"images"}
	if r.Target.Kind == "capture" {
		fields = make([]string, len(r.Poses))
		for i, pose := range r.Poses {
			fields[i] = "image_" + pose
		}
	}
	return &model.UploadTicket{Ticket: raw, URL: s.Config.UploadsURL, Fields: fields, MaxFiles: r.MaxFiles,
		MaxBytes: r.MaxBytes, ExpiresAt: expires}, nil
}

// SaveSession keeps a capture: images move from tmp/ to captures/ with a
// 30-day retention clock, and the session becomes complete (§6.2).
func (s *Services) SaveSession(ctx context.Context, p *Principal, id string) (*model.Session, error) {
	var out model.Session
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		row, err := repository.LockSession(ctx, tx, id)
		if err != nil {
			return err
		}
		if row.Status != "pending_save" {
			return conflict("invalid_transition", "Only unsaved capture results can be saved")
		}
		assets, err := repository.ListAssets(ctx, tx, id)
		if err != nil {
			return err
		}
		until := s.Now().Add(CaptureRetention)
		for _, a := range assets {
			if a.Stage == "confirmed" {
				continue
			}
			dst := fmt.Sprintf("%s/captures/%s/%s/%s.jpg", s.Store.Prefix(), row.WorkspaceID, id, a.Pose)
			if err := s.Store.Copy(ctx, a.Key, dst); err != nil && !errors.Is(err, storage.ErrMissing) {
				return err
			}
			if err := repository.ConfirmAsset(ctx, tx, a.ID, dst, until); err != nil {
				return err
			}
			_ = s.Store.Delete(ctx, a.Key)
		}
		if err := repository.UpdateSession(ctx, tx, id, repository.SessionUpdate{Status: "complete", Saved: true}); err != nil {
			return err
		}
		row, err = repository.GetSession(ctx, tx, id)
		if err == nil {
			out = view(row)
		}
		return err
	})
	return &out, err
}

// AppendCorrections adds manual_correction rows; pipeline values are never
// mutated (data-model.md §2).
func (s *Services) AppendCorrections(ctx context.Context, p *Principal, id string, ms []ManualInput) (*model.Session, error) {
	if err := validMeasurements(ms); err != nil {
		return nil, err
	}
	var out model.Session
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		row, err := repository.GetSession(ctx, tx, id)
		if err != nil {
			return err
		}
		if row.Status != "complete" && row.Status != "pending_save" {
			return conflict("invalid_transition", "Only measured sessions take corrections")
		}
		inputs := make([]repository.MeasurementInput, len(ms))
		for i, m := range ms {
			inputs[i] = repository.MeasurementInput{Name: m.Name, ValueCM: round1(m.ValueCM), Source: "manual_correction"}
		}
		if err := repository.AppendMeasurements(ctx, tx, id, row.WorkspaceID, inputs); err != nil {
			return err
		}
		row, err = repository.GetSession(ctx, tx, id)
		if err == nil {
			out = view(row)
		}
		return err
	})
	return &out, err
}

// DeleteSession removes a session and its images (history delete, or
// "Retake" discarding unsaved results).
func (s *Services) DeleteSession(ctx context.Context, p *Principal, id string) error {
	var keys []string
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		assets, err := repository.ListAssets(ctx, tx, id)
		if err != nil {
			return err
		}
		for _, a := range assets {
			keys = append(keys, a.Key)
		}
		return repository.DeleteSession(ctx, tx, id)
	})
	if err != nil {
		return err
	}
	for _, k := range keys {
		if err := s.Store.Delete(ctx, k); err != nil {
			slog.Warn("capture image delete failed; the sweep retries", "error", err)
		}
	}
	return nil
}

// ExportSession renders a PDF or CSV (formatting, not a decision, so it
// stays here: open question 4) and returns a signed URL (PLAT-004).
func (s *Services) ExportSession(ctx context.Context, p *Principal, id, format string) (*model.Export, error) {
	if format != "csv" && format != "pdf" {
		return nil, invalid("format must be csv or pdf")
	}
	var row *repository.SessionRow
	if err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		row, err = repository.GetSession(ctx, tx, id)
		return err
	}); err != nil {
		return nil, err
	}
	if row.Status != "complete" && row.Status != "pending_save" {
		return nil, conflict("invalid_transition", "Only measured sessions can be exported")
	}
	data, contentType := renderExport(row, format)
	key := fmt.Sprintf("%s/exports/%s/%s/%s.%s", s.Store.Prefix(), row.WorkspaceID, id, s.Now().UTC().Format("20060102T150405"), format)
	if err := s.Store.Put(ctx, key, data, contentType); err != nil {
		return nil, err
	}
	if err := s.as(ctx, p, func(tx pgx.Tx) error {
		return repository.InsertExport(ctx, tx, id, row.WorkspaceID, format, key)
	}); err != nil {
		return nil, err
	}
	url, err := s.Store.SignedURL(ctx, key, 15*time.Minute)
	if err != nil {
		return nil, err
	}
	return &model.Export{URL: url, Format: format}, nil
}

func renderExport(row *repository.SessionRow, format string) ([]byte, string) {
	if format == "csv" {
		var b strings.Builder
		b.WriteString("name,value_cm,source,confidence\n")
		for _, m := range row.Measurements {
			conf := ""
			if m.Confidence != nil {
				conf = trimFloat(*m.Confidence)
			}
			fmt.Fprintf(&b, "%s,%s,%s,%s\n", m.Name, trimFloat(m.ValueCM), m.Source, conf)
		}
		return []byte(b.String()), "text/csv"
	}
	lines := []string{
		"Apparule — measurement session export",
		fmt.Sprintf("Session %s · method %s", row.ID, row.Method),
		"Captured " + row.CreatedAt.UTC().Format("Mon Jan 2 2006"),
		"",
	}
	for _, m := range row.Measurements {
		line := fmt.Sprintf("%s: %s cm (%s", m.Name, trimFloat(m.ValueCM), m.Source)
		if m.Confidence != nil {
			line += ", confidence " + trimFloat(*m.Confidence)
		}
		lines = append(lines, line+")")
	}
	return minimalPDF(lines), "application/pdf"
}

// ── Consumers (§6.1) ────────────────────────────────────────────────────

type imageRef struct {
	Object struct {
		Bucket string `json:"bucket"`
		Key    string `json:"key"`
		Size   int64  `json:"size"`
	} `json:"object"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

// OnCaptureUploaded records the pose images the gateway stored, marks the
// ticket used, and hands the capture to segmentation.
func (s *Services) OnCaptureUploaded(ctx context.Context, raw json.RawMessage) error {
	var msg struct {
		TicketID  string              `json:"ticket_id"`
		AccountID string              `json:"account_id"`
		SessionID string              `json:"session_id"`
		Poses     map[string]imageRef `json:"poses"`
	}
	if err := json.Unmarshal(raw, &msg); err != nil {
		return err
	}
	var stale []string
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		t, err := repository.UseTicket(ctx, tx, msg.TicketID)
		if errors.Is(err, repository.ErrNotFound) {
			slog.Warn("upload with a used or unknown ticket; ignored", "step", "capture.uploaded", "session_id", msg.SessionID)
			return nil
		}
		if err != nil {
			return err
		}
		if t.TargetKind != "capture" || t.TargetID != msg.SessionID || t.AccountID != msg.AccountID {
			slog.Error("upload does not match its ticket; ignored", "step", "capture.uploaded", "session_id", msg.SessionID)
			return nil
		}
		row, err := repository.LockSession(ctx, tx, msg.SessionID)
		if errors.Is(err, repository.ErrNotFound) {
			return nil // deleted (retake discarded it, or the sweep expired it)
		}
		if err != nil {
			return err
		}
		if row.Status != "awaiting_upload" && row.Status != "failed_qc" {
			return nil
		}
		for _, pose := range t.Poses {
			ref, ok := msg.Poses[pose]
			if !ok {
				continue
			}
			old, err := repository.PutAsset(ctx, tx, row.ID, row.WorkspaceID, pose, ref.Object.Key, ref.Width, ref.Height, ref.Object.Size)
			if err != nil {
				return err
			}
			if old != "" {
				stale = append(stale, old)
			}
		}
		return s.sendCaptureReady(ctx, tx, row, row.Attempt+1)
	})
	for _, k := range stale {
		_ = s.Store.Delete(ctx, k)
	}
	return err
}

// sendCaptureReady queues capture.ready for the session's current images.
func (s *Services) sendCaptureReady(ctx context.Context, tx pgx.Tx, row *repository.SessionRow, attempt int) error {
	assets, err := repository.ListAssets(ctx, tx, row.ID)
	if err != nil {
		return err
	}
	if _, ok := assets["front"]; !ok {
		return nil // can't happen with a first-upload ticket; nothing to measure
	}
	if _, ok := assets["side"]; !ok {
		return nil
	}
	template := "women"
	if row.Template != nil {
		template = *row.Template
	}
	posesOut := map[string]any{}
	for pose, a := range assets {
		posesOut[pose] = map[string]any{
			"object": map[string]any{"bucket": s.Store.Bucket(), "key": a.Key, "size": a.Size, "content_type": "image/jpeg"},
			"width":  a.Width, "height": a.Height,
		}
	}
	now := s.Now()
	if err := repository.UpdateSession(ctx, tx, row.ID, repository.SessionUpdate{
		Status: "processing", Attempt: &attempt, ClearQC: true, ProcessingSince: &now,
	}); err != nil {
		return err
	}
	return repository.Enqueue(ctx, tx, kafka.EventCaptureReady, row.ID, map[string]any{
		"session_id": row.ID, "attempt": attempt, "method": "mediapipe_2d_v2", "height_cm": *row.InputHeightCM,
		"template": template, "measures": Templates[template], "poses": posesOut,
	})
}

// OnCaptureMeasured stores segmentation's verdict for the current attempt.
func (s *Services) OnCaptureMeasured(ctx context.Context, raw json.RawMessage) error {
	var msg struct {
		SessionID         string            `json:"session_id"`
		Attempt           int               `json:"attempt"`
		Status            string            `json:"status"`
		Method            string            `json:"method"`
		ThresholdsVersion string            `json:"thresholds_version"`
		Poses             map[string]string `json:"poses"`
		QC                *struct {
			Code string `json:"code"`
			Pose string `json:"pose"`
		} `json:"qc"`
		Measurements []struct {
			Name       string   `json:"name"`
			ValueCM    float64  `json:"value_cm"`
			Confidence *float64 `json:"confidence"`
		} `json:"measurements"`
		Meta      map[string]any `json:"meta"`
		ErrorCode *string        `json:"error_code"`
	}
	if err := json.Unmarshal(raw, &msg); err != nil {
		return err
	}
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		row, err := repository.LockSession(ctx, tx, msg.SessionID)
		if errors.Is(err, repository.ErrNotFound) {
			return nil
		}
		if err != nil {
			return err
		}
		if row.Status != "processing" || row.Attempt != msg.Attempt {
			return nil // a stale result for an older attempt, or a redelivery
		}
		for pose, verdict := range msg.Poses {
			if err := repository.SetAssetVerdict(ctx, tx, row.ID, pose, verdict == "accepted"); err != nil {
				return err
			}
		}
		meta := map[string]any{"qc": map[string]any{"thresholds_version": msg.ThresholdsVersion}}
		for k, v := range msg.Meta {
			if k == "height_suspect" {
				meta["qc"].(map[string]any)[k] = v
				continue
			}
			meta[k] = v
		}
		metaRaw, _ := json.Marshal(meta)
		update := repository.SessionUpdate{PipelineMeta: metaRaw, ClearProcessing: true}
		switch msg.Status {
		case "measured":
			update.Status = "pending_save"
			inputs := make([]repository.MeasurementInput, 0, len(msg.Measurements))
			for _, m := range msg.Measurements {
				inputs = append(inputs, repository.MeasurementInput{Name: m.Name, ValueCM: round1(m.ValueCM), Source: "pipeline", Confidence: m.Confidence})
			}
			if err := repository.AppendMeasurements(ctx, tx, row.ID, row.WorkspaceID, inputs); err != nil {
				return err
			}
		case "failed_qc":
			update.Status = "failed_qc"
			update.QCCode, update.QCPose = &msg.QC.Code, &msg.QC.Pose
		default:
			update.Status = "failed"
			update.ErrorCode = msg.ErrorCode
		}
		if err := repository.UpdateSession(ctx, tx, row.ID, update); err != nil {
			return err
		}
		owner, err := sessionOwner(ctx, tx, row.CustomerID)
		if err != nil || owner == "" {
			return err
		}
		// A silent push so a backgrounded app refreshes (§6.1).
		return notify(ctx, tx, note{To: owner, Kind: "capture_result", PayloadRef: row.ID, RefKind: "session", Text: "Your measurements are ready"})
	})
}

func sessionOwner(ctx context.Context, tx pgx.Tx, customerID string) (string, error) {
	var account *string
	err := tx.QueryRow(ctx, `SELECT account_id FROM customer WHERE id = $1`, customerID).Scan(&account)
	if err != nil || account == nil {
		return "", err
	}
	return *account, nil
}

// ── helpers ─────────────────────────────────────────────────────────────

func round1(v float64) float64 { return math.Round(v*10) / 10 }

func trimFloat(v float64) string {
	return strings.TrimRight(strings.TrimRight(fmt.Sprintf("%.2f", v), "0"), ".")
}

func optional(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func nonNil(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}
