package service_test

import (
	"context"
	"crypto/ed25519"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha512"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	embeddedpostgres "github.com/fergusstrange/embedded-postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
	"github.com/cuesoftinc/apparule/api/common/internal/ticket"
	"github.com/cuesoftinc/apparule/api/common/migrations"
)

// The integration suite runs against a real Postgres as a NON-superuser
// role that owns the tables, so FORCE row-level security is enforced. It
// uses TEST_DATABASE_URL (a superuser URL) when set, else an embedded
// Postgres.

type memStore struct{ objects map[string][]byte }

func (m *memStore) Bucket() string { return "test" }
func (m *memStore) Prefix() string { return "apparule/test" }
func (m *memStore) Put(_ context.Context, k string, d []byte, _ string) error {
	m.objects[k] = d
	return nil
}
func (m *memStore) Get(_ context.Context, k string) ([]byte, error) {
	d, ok := m.objects[k]
	if !ok {
		return nil, storage.ErrMissing
	}
	return d, nil
}
func (m *memStore) Delete(_ context.Context, k string) error { delete(m.objects, k); return nil }
func (m *memStore) List(context.Context, string) ([]storage.Object, error) {
	return nil, nil
}
func (m *memStore) Copy(_ context.Context, src, dst string) error {
	d, ok := m.objects[src]
	if !ok {
		return storage.ErrMissing
	}
	m.objects[dst] = d
	return nil
}
func (m *memStore) SignedURL(_ context.Context, k string, _ time.Duration) (string, error) {
	return "https://signed.test/" + k, nil
}

const paystackSecret = "sk_test_secret"

type env struct {
	db       *repository.DB
	store    *memStore
	contract *kafka.Contract
	s        *service.Services
}

func freePort(t *testing.T) uint32 {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	return uint32(l.Addr().(*net.TCPAddr).Port)
}

func setup(t *testing.T) *env {
	if testing.Short() {
		t.Skip("integration test")
	}
	ctx := context.Background()
	superURL := os.Getenv("TEST_DATABASE_URL")
	if superURL == "" {
		port := freePort(t)
		dir := t.TempDir()
		pg := embeddedpostgres.NewDatabase(embeddedpostgres.DefaultConfig().Port(port).
			RuntimePath(filepath.Join(dir, "run")).DataPath(filepath.Join(dir, "data")).StartTimeout(2 * time.Minute))
		if err := pg.Start(); err != nil {
			t.Fatalf("embedded postgres: %v", err)
		}
		t.Cleanup(func() { _ = pg.Stop() })
		superURL = fmt.Sprintf("postgres://postgres:postgres@127.0.0.1:%d/postgres?sslmode=disable", port)
	}

	super, err := pgx.Connect(ctx, superURL)
	if err != nil {
		t.Fatal(err)
	}
	dbName := fmt.Sprintf("apparule_test_%d", time.Now().UnixNano())
	for _, stmt := range []string{
		`DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'apparule_app') THEN
			CREATE ROLE apparule_app LOGIN PASSWORD 'app' NOSUPERUSER NOBYPASSRLS; END IF; END $$`,
		`CREATE DATABASE ` + dbName + ` OWNER apparule_app`,
	} {
		if _, err := super.Exec(ctx, stmt); err != nil {
			t.Fatal(err)
		}
	}
	super.Close(ctx)

	appURL := strings.Replace(superURL, "postgres:postgres@", "apparule_app:app@", 1)
	appURL = appURL[:strings.LastIndex(appURL, "/")+1] + dbName + "?sslmode=disable"
	pool, err := pgxpool.New(ctx, appURL)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if err := migrations.Apply(ctx, pool); err != nil {
		t.Fatal(err)
	}
	db := &repository.DB{Pool: pool}

	_, key, _ := ed25519.GenerateKey(rand.Reader)
	contract, err := kafka.LoadContract()
	if err != nil {
		t.Fatal(err)
	}
	cfg := &config.Config{UploadsURL: "/api/v1/uploads", Paystack: config.Paystack{SecretKey: paystackSecret, PublicKey: "pk_test"},
		Limits: config.Limits{ImageMaxBytes: 10 << 20, UploadBytesDay: 100 << 20, CapturesPerMin: 10, CapturesPerDay: 100,
			SocialPerMin: 60, CommentsPerMin: 10, RequestsPerDay: 20, OpenRequests: 10, PostsPerDay: 20,
			ProcessingResend: time.Minute, ProcessingFail: 3 * time.Minute}}
	store := &memStore{objects: map[string][]byte{}}
	return &env{db: db, store: store, contract: contract, s: &service.Services{
		DB: db, Store: store, Tickets: ticket.NewSigner("test", key, 5*time.Minute), Config: cfg, Now: time.Now}}
}

func (e *env) signIn(t *testing.T, uid, email string) *service.Principal {
	p, err := e.s.SignIn(context.Background(), &auth.Identity{UID: uid, Email: email, Name: strings.Split(email, "@")[0]})
	if err != nil {
		t.Fatal(err)
	}
	return p
}

// refresh reloads the principal (designer id, KYC) after changes.
func (e *env) refresh(t *testing.T, p *service.Principal) *service.Principal {
	var out *service.Principal
	if err := e.db.AsSystem(context.Background(), func(tx pgx.Tx) error {
		var err error
		out, err = repository.LoadPrincipal(context.Background(), tx, p.AccountID)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	return out
}

// outbox returns unsent payloads for an event, each validated against the
// contract, and marks them sent.
func (e *env) outbox(t *testing.T, event string) []map[string]any {
	var out []map[string]any
	err := e.db.AsSystem(context.Background(), func(tx pgx.Tx) error {
		rows, err := tx.Query(context.Background(), `UPDATE outbox SET published_at = now()
			WHERE event = $1 AND published_at IS NULL RETURNING payload`, event)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var raw []byte
			if err := rows.Scan(&raw); err != nil {
				return err
			}
			if err := e.contract.Validate(event, raw); err != nil {
				t.Errorf("outbox %s violates the contract: %v\n%s", event, err, raw)
			}
			var m map[string]any
			_ = json.Unmarshal(raw, &m)
			out = append(out, m)
		}
		return rows.Err()
	})
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// deliver validates a message for a consumer and hands it over.
func (e *env) deliver(t *testing.T, event string, data any, handler kafka.Handler) {
	e.deliverAs(t, event, "", data, handler)
}

// deliverAs is deliver for a message carrying a request_id.
func (e *env) deliverAs(t *testing.T, event, requestID string, data any, handler kafka.Handler) {
	raw, err := json.Marshal(data)
	if err != nil {
		t.Fatal(err)
	}
	if err := e.contract.Validate(event, raw); err != nil {
		t.Fatalf("test message for %s violates the contract: %v\n%s", event, err, raw)
	}
	if err := handler(kafka.WithRequestID(context.Background(), requestID), raw); err != nil {
		t.Fatalf("%s handler: %v", event, err)
	}
}

// system runs a query as the system and fails the test on error.
func (e *env) system(t *testing.T, fn func(ctx context.Context, tx pgx.Tx) error) {
	ctx := context.Background()
	if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error { return fn(ctx, tx) }); err != nil {
		t.Fatal(err)
	}
}

func claimsOf(t *testing.T, raw string) ticket.Claims {
	parts := strings.Split(raw, ".")
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		t.Fatal(err)
	}
	var c ticket.Claims
	if err := json.Unmarshal(payload, &c); err != nil {
		t.Fatal(err)
	}
	return c
}

func image(key string) map[string]any {
	return map[string]any{"object": map[string]any{"bucket": "test", "key": key, "size": 600_000}, "width": 1536, "height": 2048}
}

func ready(e *env, t *testing.T, p *service.Principal) {
	ctx := context.Background()
	for _, d := range []string{"tos", "privacy"} {
		if _, err := e.s.RecordConsent(ctx, p, d, "2026-07"); err != nil {
			t.Fatal(err)
		}
	}
	tmpl := "women"
	if _, err := e.s.UpdateMe(ctx, p, service.MePatch{MeasurementTemplate: &tmpl, TemplateSet: true}); err != nil {
		t.Fatal(err)
	}
}

func code(err error) string {
	var apiErr *service.Error
	if errors.As(err, &apiErr) {
		return apiErr.Code
	}
	if errors.Is(err, repository.ErrNotFound) {
		return "not_found"
	}
	if err != nil {
		return err.Error()
	}
	return ""
}

func TestCaptureFlow(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")

	// Consent and the template gate come first (flows/vault.md).
	if _, err := e.s.CreateCapture(ctx, kiki, 168, ""); code(err) != "consent_required" {
		t.Fatalf("want consent_required, got %v", err)
	}
	for _, d := range []string{"tos", "privacy"} {
		if _, err := e.s.RecordConsent(ctx, kiki, d, "2026-07"); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := e.s.CreateCapture(ctx, kiki, 168, ""); code(err) != "template_required" {
		t.Fatalf("want template_required, got %v", err)
	}
	tmpl := "women"
	if _, err := e.s.UpdateMe(ctx, kiki, service.MePatch{MeasurementTemplate: &tmpl, TemplateSet: true}); err != nil {
		t.Fatal(err)
	}

	started, err := e.s.CreateCapture(ctx, kiki, 168, "key-1")
	if err != nil {
		t.Fatal(err)
	}
	again, err := e.s.CreateCapture(ctx, kiki, 168, "key-1")
	if err != nil || again.ID != started.ID {
		t.Fatalf("retried create must return the same session: %v %s %s", err, again.ID, started.ID)
	}
	if started.Status != "awaiting_upload" || started.Upload.MaxFiles != 2 {
		t.Fatalf("started: %+v", started)
	}
	first := claimsOf(t, started.Upload.Ticket)
	if first.Target.ID != started.ID || len(first.Poses) != 2 {
		t.Fatalf("ticket claims: %+v", first)
	}

	// The gateway stored both poses.
	upload := func(jti string, poses map[string]any) {
		e.deliver(t, kafka.EventCaptureUploaded, map[string]any{"ticket_id": jti, "account_id": kiki.AccountID,
			"session_id": started.ID, "poses": poses}, e.s.OnCaptureUploaded)
	}
	front, side := "apparule/test/tmp/capture/s/1/front.jpg", "apparule/test/tmp/capture/s/1/side.jpg"
	e.store.objects[front], e.store.objects[side] = []byte("f"), []byte("s")
	upload(first.JTI, map[string]any{"front": image(front), "side": image(side)})
	readyMsgs := e.outbox(t, kafka.EventCaptureReady)
	if len(readyMsgs) != 1 || readyMsgs[0]["attempt"].(float64) != 1 || len(readyMsgs[0]["measures"].([]any)) != 17 {
		t.Fatalf("capture.ready: %+v", readyMsgs)
	}
	// Single use: a replayed upload changes nothing.
	upload(first.JTI, map[string]any{"front": image(front), "side": image(side)})
	if n := len(e.outbox(t, kafka.EventCaptureReady)); n != 0 {
		t.Fatalf("replayed ticket queued %d more captures", n)
	}

	// The side pose fails QC; the front is kept.
	e.deliver(t, kafka.EventCaptureMeasured, map[string]any{"session_id": started.ID, "attempt": 1, "status": "failed_qc",
		"method": "mediapipe_2d_v2", "thresholds_version": "qc-test", "poses": map[string]string{"front": "accepted", "side": "failed"},
		"qc": map[string]string{"code": "not_side_profile", "pose": "side"}}, e.s.OnCaptureMeasured)
	s, err := e.s.Session(ctx, kiki, started.ID)
	if err != nil || s.Status != "failed_qc" || s.QC == nil || s.QC.Guidance != "Turn your right side to the camera" || s.Poses["front"] != "accepted" {
		t.Fatalf("after failed_qc: %v %+v", err, s)
	}
	if _, err := e.s.RetakeTicket(ctx, kiki, started.ID, "front"); code(err) != "pose_accepted" {
		t.Fatalf("an accepted pose can't be retaken: %v", err)
	}
	retake, err := e.s.RetakeTicket(ctx, kiki, started.ID, "side")
	if err != nil || retake.Upload.MaxFiles != 1 {
		t.Fatalf("retake: %v %+v", err, retake)
	}
	side2 := "apparule/test/tmp/capture/s/2/side.jpg"
	e.store.objects[side2] = []byte("s2")
	upload(claimsOf(t, retake.Upload.Ticket).JTI, map[string]any{"side": image(side2)})
	readyMsgs = e.outbox(t, kafka.EventCaptureReady)
	poses := readyMsgs[0]["poses"].(map[string]any)
	if readyMsgs[0]["attempt"].(float64) != 2 || poses["front"].(map[string]any)["object"].(map[string]any)["key"] != front ||
		poses["side"].(map[string]any)["object"].(map[string]any)["key"] != side2 {
		t.Fatalf("retake capture.ready: %+v", readyMsgs[0])
	}
	if _, ok := e.store.objects[side]; ok {
		t.Fatal("the replaced side image should be deleted")
	}

	// A stale result for attempt 1 is ignored; attempt 2 measures.
	measured := func(attempt int) map[string]any {
		return map[string]any{"session_id": started.ID, "attempt": attempt, "status": "measured", "method": "mediapipe_2d_v2",
			"thresholds_version": "qc-test", "poses": map[string]string{"front": "accepted", "side": "accepted"},
			"measurements": []map[string]any{{"name": "bust", "value_cm": 91.24, "confidence": 0.74}, {"name": "waist", "value_cm": 74.8, "confidence": 0.71}},
			"meta":         map[string]any{"height_suspect": false, "ms": 1800}}
	}
	e.deliver(t, kafka.EventCaptureMeasured, measured(1), e.s.OnCaptureMeasured)
	if s, _ := e.s.Session(ctx, kiki, started.ID); s.Status != "processing" {
		t.Fatalf("a stale attempt must not apply: %s", s.Status)
	}
	e.deliver(t, kafka.EventCaptureMeasured, measured(2), e.s.OnCaptureMeasured)
	s, _ = e.s.Session(ctx, kiki, started.ID)
	if s.Status != "pending_save" || len(s.Measurements) != 2 || s.Measurements[0].ValueCM != 91.2 {
		t.Fatalf("measured: %+v", s)
	}
	// One silent push per result: the failed check, then the measurements.
	if n := len(e.outbox(t, kafka.EventNotificationsCreated)); n != 2 {
		t.Fatalf("want two capture-result pushes, got %d", n)
	}

	// Another account sees nothing (S-11 RLS).
	other := e.signIn(t, "uid-other", "other@example.com")
	if _, err := e.s.Session(ctx, other, started.ID); code(err) != "not_found" {
		t.Fatalf("cross-account read: %v", err)
	}
	if err := e.s.DeleteSession(ctx, other, started.ID); code(err) != "not_found" {
		t.Fatalf("cross-account delete: %v", err)
	}

	// Save moves both images to captures/ with a 30-day clock.
	saved, err := e.s.SaveSession(ctx, kiki, started.ID)
	if err != nil || saved.Status != "complete" {
		t.Fatalf("save: %v %+v", err, saved)
	}
	for _, k := range []string{front, side2} {
		if _, ok := e.store.objects[k]; ok {
			t.Fatalf("tmp image %s should be gone after save", k)
		}
	}
	confirmed := 0
	for k := range e.store.objects {
		if strings.Contains(k, "/captures/") {
			confirmed++
		}
	}
	if confirmed != 2 {
		t.Fatalf("want 2 confirmed images, have %d", confirmed)
	}
	list, err := e.s.Sessions(ctx, kiki, service.Paging{Limit: 50})
	if err != nil || len(fmt.Sprint(list)) == 0 {
		t.Fatal(err)
	}

	// Corrections append; the export is a signed URL.
	if _, err := e.s.AppendCorrections(ctx, kiki, started.ID, []service.ManualInput{{Name: "waist", ValueCM: 76}}); err != nil {
		t.Fatal(err)
	}
	exp, err := e.s.ExportSession(ctx, kiki, started.ID, "pdf")
	if err != nil || !strings.HasPrefix(exp.URL, "https://signed.test/apparule/test/exports/") {
		t.Fatalf("export: %v %+v", err, exp)
	}
}

func TestCaptureSweeps(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")
	ready(e, t, kiki)
	started, err := e.s.CreateCapture(ctx, kiki, 170, "")
	if err != nil {
		t.Fatal(err)
	}
	front, side := "apparule/test/tmp/a/front.jpg", "apparule/test/tmp/a/side.jpg"
	e.deliver(t, kafka.EventCaptureUploaded, map[string]any{"ticket_id": claimsOf(t, started.Upload.Ticket).JTI,
		"account_id": kiki.AccountID, "session_id": started.ID, "poses": map[string]any{"front": image(front), "side": image(side)}},
		e.s.OnCaptureUploaded)
	e.outbox(t, kafka.EventCaptureReady)

	// Overdue: re-sent once (X-11), then failed as pipeline_busy.
	age := func(d time.Duration) {
		if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error {
			_, err := tx.Exec(ctx, `UPDATE measurement_session SET processing_since = now() - make_interval(secs => $2) WHERE id = $1`,
				started.ID, d.Seconds())
			return err
		}); err != nil {
			t.Fatal(err)
		}
	}
	age(90 * time.Second)
	if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error { return e.s.ResendCapture(ctx, tx, started.ID) }); err != nil {
		t.Fatal(err)
	}
	if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error { return e.s.ResendCapture(ctx, tx, started.ID) }); err != nil {
		t.Fatal(err)
	}
	if n := len(e.outbox(t, kafka.EventCaptureReady)); n != 1 {
		t.Fatalf("want exactly one re-send, got %d", n)
	}
	// The re-send keeps the request_id, so a result to either copy counts once.
	var requestIDs []string
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT request_id FROM outbox WHERE event = $1 ORDER BY id`, kafka.EventCaptureReady)
		if err != nil {
			return err
		}
		requestIDs, err = pgx.CollectRows(rows, pgx.RowTo[string])
		return err
	})
	if len(requestIDs) != 2 || requestIDs[0] != started.ID+":1" || requestIDs[1] != requestIDs[0] {
		t.Fatalf("capture.ready request ids: %v", requestIDs)
	}

	// A result common can't store after retries fails the attempt.
	raw, _ := json.Marshal(map[string]any{"session_id": started.ID, "attempt": 1})
	if err := e.s.OnCaptureMeasuredFailed(ctx, raw, errors.New("database away")); err != nil {
		t.Fatal(err)
	}
	if s, err := e.s.Session(ctx, kiki, started.ID); err != nil || s.Status != "failed" || s.ErrorCode == nil || *s.ErrorCode != "pipeline_error" {
		t.Fatalf("after a failed result: %v %+v", err, s)
	}
}

func TestFirstResultWins(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")
	ready(e, t, kiki)
	started, err := e.s.CreateCapture(ctx, kiki, 170, "")
	if err != nil {
		t.Fatal(err)
	}
	e.deliver(t, kafka.EventCaptureUploaded, map[string]any{"ticket_id": claimsOf(t, started.Upload.Ticket).JTI,
		"account_id": kiki.AccountID, "session_id": started.ID,
		"poses": map[string]any{"front": image("apparule/test/tmp/b/front.jpg"), "side": image("apparule/test/tmp/b/side.jpg")}},
		e.s.OnCaptureUploaded)
	result := func(status string) map[string]any {
		r := map[string]any{"session_id": started.ID, "attempt": 1, "status": status, "method": "mediapipe_2d_v2",
			"thresholds_version": "qc-test", "poses": map[string]string{}}
		if status == "failed" {
			r["error_code"] = "pipeline_error"
		} else {
			r["poses"] = map[string]string{"front": "accepted", "side": "accepted"}
			r["measurements"] = []map[string]any{{"name": "bust", "value_cm": 91.2, "confidence": 0.7}}
		}
		return r
	}
	requestID := started.ID + ":1"
	e.deliverAs(t, kafka.EventCaptureMeasured, requestID, result("failed"), e.s.OnCaptureMeasured)
	// A later result for the same request (a re-sent copy measured) is ignored.
	if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE measurement_session SET status = 'processing' WHERE id = $1`, started.ID)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	e.deliverAs(t, kafka.EventCaptureMeasured, requestID, result("measured"), e.s.OnCaptureMeasured)
	if s, _ := e.s.Session(ctx, kiki, started.ID); s.Status != "processing" || len(s.Measurements) != 0 {
		t.Fatalf("a second result for one request must not apply: %+v", s)
	}
}

func TestCommissionMoneyFlow(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	designer := e.signIn(t, "uid-ada", "ada@example.com")
	customer := e.signIn(t, "uid-kiki", "kiki@example.com")
	ready(e, t, customer)

	if _, err := e.s.EnableDesigner(ctx, designer, "Ada Designs", "Bespoke · Lagos"); err != nil {
		t.Fatal(err)
	}
	designer = e.refresh(t, designer)

	// Post media: create-then-upload, then publish.
	batch, err := e.s.StartPostMedia(ctx, designer, 1)
	if err != nil {
		t.Fatal(err)
	}
	mediaKey := "apparule/test/tmp/post_media/b/1/0.jpg"
	e.store.objects[mediaKey] = []byte("img")
	e.deliver(t, kafka.EventMediaUploaded, map[string]any{"ticket_id": claimsOf(t, batch.Upload.Ticket).JTI, "account_id": designer.AccountID,
		"target": map[string]string{"kind": "post_media", "id": batch.ID}, "images": []any{image(mediaKey)}}, e.s.OnMediaUploaded)
	got, err := e.s.MediaBatch(ctx, designer, batch.ID)
	if err != nil || got.Status != "ready" || len(got.Items) != 1 {
		t.Fatalf("batch: %v %+v", err, got)
	}
	price := int64(4_500_000)
	post, err := e.s.CreatePost(ctx, designer, service.PostInput{Caption: "Ankara wrap gown — made to measure", StyleTags: []string{"Ankara"},
		BasePriceCents: &price, Media: []struct {
			MediaID string `json:"media_id"`
			URL     string `json:"url"`
			AltText string `json:"alt_text"`
		}{{URL: "/api/v1/media/" + got.Items[0].ID}}})
	if err != nil {
		t.Fatal(err)
	}
	if post.Media[0].AltText != "Outfit by Ada Designs" || !strings.HasPrefix(post.Media[0].URL, "https://signed.test/apparule/test/media/") {
		t.Fatalf("post media: %+v", post.Media)
	}

	// The customer measures manually, follows, and sees the post in the feed.
	sess, err := e.s.CreateManualSession(ctx, customer, []service.ManualInput{{Name: "bust", ValueCM: 92}, {Name: "waist", ValueCM: 74}}, "")
	if err != nil {
		t.Fatal(err)
	}
	if err := e.s.SetFollow(ctx, customer, designer.Username, true); err != nil {
		t.Fatal(err)
	}
	feed, err := e.s.Feed(ctx, customer, "", 10)
	if err != nil || len(feed.Items) != 1 || feed.Items[0].ID != post.ID {
		t.Fatalf("feed: %v %+v", err, feed)
	}
	if err := e.s.SetLike(ctx, customer, post.ID, true); err != nil {
		t.Fatal(err)
	}
	if err := e.s.SetLike(ctx, customer, post.ID, true); err != nil {
		t.Fatal(err)
	}
	if p, _ := e.s.Post(ctx, customer, post.ID); p.LikeCount != 1 || !p.Liked {
		t.Fatalf("idempotent like: %+v", p)
	}

	delivery := map[string]string{"recipient_name": "Kiki", "phone": "+2348000000000", "line1": "1 Allen Ave", "city": "Ikeja", "state": "Lagos", "country": "NG"}
	var in service.RequestInput
	raw, _ := json.Marshal(map[string]any{"session_id": sess.ID, "notes": "Floor length", "delivery": delivery})
	_ = json.Unmarshal(raw, &in)

	// A-2: no requests before the designer's KYC is verified.
	if _, err := e.s.CreateRequest(ctx, customer, post.ID, in); code(err) != "post_unavailable" {
		t.Fatalf("want post_unavailable, got %v", err)
	}
	pa, err := e.s.SubmitPayoutAccount(ctx, designer, "058", "0123456789")
	if err != nil || pa.KYCState != "pending" {
		t.Fatalf("payout account: %v %+v", err, pa)
	}
	recip := e.outbox(t, kafka.EventPayoutsRecipient)
	e.deliver(t, kafka.EventPaymentsOutcome, map[string]any{"outcome_id": uuid.NewString(), "kind": "recipient_verified",
		"designer_id": recip[0]["designer_id"], "attempt_id": recip[0]["attempt_id"],
		"recipient": map[string]string{"recipient_code": "RCP_test", "account_name": "ADA DESIGNS", "bank_name": "GTBank", "last4": "6789"}},
		e.s.OnPaymentOutcome)

	order, err := e.s.CreateRequest(ctx, customer, post.ID, in)
	if err != nil {
		t.Fatal(err)
	}
	if order.Snapshot.Values.Measurements[0].ValueCM != 92 || order.Status != "requested" {
		t.Fatalf("order: %+v", order)
	}
	if _, err := e.s.CreateRequest(ctx, customer, post.ID, in); code(err) != "duplicate_request" {
		t.Fatalf("want duplicate_request, got %v", err)
	}
	// Party only (RLS): a third account reads not_found.
	stranger := e.signIn(t, "uid-x", "x@example.com")
	if _, err := e.s.Order(ctx, stranger, order.ID); code(err) != "not_found" {
		t.Fatalf("stranger read: %v", err)
	}

	if _, err := e.s.Quote(ctx, designer, order.ID, 4_500_000, "2026-11-30"); err != nil {
		t.Fatal(err)
	}
	paid, err := e.s.Pay(ctx, customer, order.ID)
	if err != nil || paid.Checkout == nil || paid.Status != "quoted" {
		t.Fatalf("pay starts a checkout, not a transition: %v %+v", err, paid)
	}
	// Once a checkout started, the quote it was started for can't change.
	if _, err := e.s.Quote(ctx, designer, order.ID, 4_000_000, "2026-11-30"); code(err) != "payment_in_progress" {
		t.Fatalf("want payment_in_progress, got %v", err)
	}
	// Every checkout gets its own reference.
	retried, err := e.s.Pay(ctx, customer, order.ID)
	if err != nil || retried.Checkout.Reference == paid.Checkout.Reference {
		t.Fatalf("a second checkout needs a new reference: %v %+v", err, retried.Checkout)
	}

	// Paystack's webhook: verified, stored, handed to commerce once. The
	// first checkout's reference still finds the order.
	body := []byte(fmt.Sprintf(`{"event":"charge.success","data":{"id":4099260516,"reference":%q,"amount":4500000,"currency":"NGN","status":"success"}}`,
		paid.Checkout.Reference))
	mac := hmac.New(sha512.New, []byte(paystackSecret))
	mac.Write(body)
	sig := hex.EncodeToString(mac.Sum(nil))
	if err := e.s.ReceiveWebhook(ctx, body, "bad"); !errors.Is(err, service.ErrBadSignature) {
		t.Fatalf("bad signature: %v", err)
	}
	for range 2 {
		if err := e.s.ReceiveWebhook(ctx, body, sig); err != nil {
			t.Fatal(err)
		}
	}
	events := e.outbox(t, kafka.EventPaymentsProviderEvent)
	if len(events) != 1 || events[0]["order"].(map[string]any)["request_id"] != order.ID ||
		events[0]["order"].(map[string]any)["payment"].(map[string]any)["amount"].(float64) != 4_500_000 {
		t.Fatalf("provider events: %+v", events)
	}

	settle := map[string]any{"outcome_id": uuid.NewString(), "kind": "charge_settled", "request_id": order.ID,
		"provider_event_id": events[0]["provider_event_id"], "reference": paid.Checkout.Reference, "provider_ref": "4099260516",
		"amount": map[string]any{"amount": 4_500_000, "currency": "NGN"}, "fee": map[string]any{"amount": 450_000, "currency": "NGN"},
		"ledger": []map[string]any{{"account": "escrow", "amount": 4_500_000}, {"account": "customer_funds", "amount": -4_500_000}}}
	e.deliver(t, kafka.EventPaymentsOutcome, settle, e.s.OnPaymentOutcome)
	e.deliver(t, kafka.EventPaymentsOutcome, settle, e.s.OnPaymentOutcome) // redelivered: stored once
	o, _ := e.s.Order(ctx, customer, order.ID)
	if o.Status != "paid" || o.Payment == nil || o.Payment.State != "held" || o.Payment.PlatformFeeCents != 450_000 {
		t.Fatalf("after settlement: %+v", o)
	}

	// A second charge for the order (another checkout paid too) books no
	// escrow; it is flagged for a refund.
	escrow := func() int64 {
		var n int64
		e.system(t, func(ctx context.Context, tx pgx.Tx) error {
			var err error
			n, err = repository.LedgerBalance(ctx, tx, "escrow")
			return err
		})
		return n
	}
	second := map[string]any{}
	for k, v := range settle {
		second[k] = v
	}
	second["outcome_id"], second["reference"], second["provider_ref"] = uuid.NewString(), retried.Checkout.Reference, "4099260999"
	e.deliver(t, kafka.EventPaymentsOutcome, second, e.s.OnPaymentOutcome)
	if n := escrow(); n != 4_500_000 {
		t.Fatalf("a second charge must not book escrow: escrow is %d", n)
	}
	var attention *string
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT attention FROM payment_outcome WHERE outcome_id = $1`, second["outcome_id"]).Scan(&attention)
	})
	if attention == nil || *attention != "refund_needed" {
		t.Fatalf("the second charge needs a refund: %v", attention)
	}

	for _, step := range []string{"in_progress", "shipped"} {
		if _, err := e.s.SetStatus(ctx, designer, order.ID, step, nil); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := e.s.ConfirmDelivery(ctx, customer, order.ID); err != nil {
		t.Fatal(err)
	}
	var delivered map[string]any
	for _, tr := range e.outbox(t, kafka.EventOrdersTransition) {
		if tr["to"] == "delivered" {
			delivered = tr
		}
	}
	if delivered == nil || delivered["payout_recipient"].(map[string]any)["recipient_code"] != "RCP_test" ||
		delivered["payment"].(map[string]any)["reference"] != paid.Checkout.Reference {
		t.Fatalf("delivered transition: %+v", delivered)
	}
	// The designer, not the customer who confirmed, hears about delivery.
	if list, err := e.s.Notifications(ctx, designer, service.Paging{Limit: 50}); err != nil ||
		!strings.Contains(fmt.Sprint(list), "Order #"+order.OrderNumber+" was delivered; your payout is on its way") {
		t.Fatalf("designer notifications: %v %v", err, list)
	}
	if list, _ := e.s.Notifications(ctx, customer, service.Paging{Limit: 50}); strings.Contains(fmt.Sprint(list), "delivered") {
		t.Fatalf("the customer confirmed delivery and needs no note of it: %v", list)
	}

	payoutRequest := uuid.NewString()
	e.deliverAs(t, kafka.EventPaymentsOutcome, payoutRequest, map[string]any{"outcome_id": uuid.NewString(), "kind": "payout_released", "request_id": order.ID,
		"transition_id": delivered["transition_id"], "provider_ref": "TRF_test", "amount": map[string]any{"amount": 4_050_000, "currency": "NGN"},
		"fee": map[string]any{"amount": 450_000, "currency": "NGN"},
		"ledger": []map[string]any{{"account": "escrow", "amount": -4_500_000}, {"account": "designer_payable", "amount": 4_050_000},
			{"account": "platform_fee", "amount": 450_000}}}, e.s.OnPaymentOutcome)
	// A later result for the same request is ignored: the first one won.
	e.deliverAs(t, kafka.EventPaymentsOutcome, payoutRequest, map[string]any{"outcome_id": uuid.NewString(), "kind": "payout_failed",
		"request_id": order.ID, "transition_id": delivered["transition_id"], "reason": "processing_failed"}, e.s.OnPaymentOutcome)
	var payoutState string
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT state FROM payout WHERE request_id = $1`, order.ID).Scan(&payoutState)
	})
	if payoutState != "paid" {
		t.Fatalf("the first result for a request wins: payout is %s", payoutState)
	}
	earn, err := e.s.Earnings(ctx, e.refresh(t, designer))
	if err != nil || earn.BalanceCents != 4_050_000 || len(earn.Transactions) != 2 {
		t.Fatalf("earnings: %v %+v", err, earn)
	}

	// The money invariant: escrow is empty once the payout is released.
	if err := e.db.AsSystem(ctx, func(tx pgx.Tx) error {
		escrow, err := repository.LedgerBalance(ctx, tx, "escrow")
		if err == nil && escrow != 0 {
			return fmt.Errorf("escrow should be 0, is %d", escrow)
		}
		return err
	}); err != nil {
		t.Fatal(err)
	}
	// Unbalanced lines are rejected at commit.
	err = e.db.AsSystem(ctx, func(tx pgx.Tx) error {
		id := uuid.NewString()
		if _, err := repository.RecordOutcome(ctx, tx, id, "mismatch", &order.ID, nil, nil, json.RawMessage(`{}`)); err != nil {
			return err
		}
		return repository.AppendLedger(ctx, tx, id, order.ID, "NGN", []repository.LedgerLine{{Account: "escrow", Amount: 1}})
	})
	if err == nil {
		t.Fatal("an unbalanced ledger movement must not commit")
	}

	// Notifications reached both parties and respect the visible kinds.
	list, err := e.s.Notifications(ctx, customer, service.Paging{Limit: 50})
	if err != nil || !strings.Contains(fmt.Sprint(list), "Payment received") {
		t.Fatalf("customer notifications: %v %v", err, list)
	}
}

func TestBlocksHideContent(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	a := e.signIn(t, "uid-a", "a@example.com")
	b := e.signIn(t, "uid-b", "b@example.com")
	if _, err := e.s.EnableDesigner(ctx, b, "B", ""); err != nil {
		t.Fatal(err)
	}
	if err := e.s.SetBlock(ctx, a, b.Username, true); err != nil {
		t.Fatal(err)
	}
	if err := e.s.SetFollow(ctx, a, b.Username, true); code(err) != "not_found" {
		t.Fatalf("a blocked pair can't follow: %v", err)
	}
	if _, err := e.s.Profile(ctx, a, b.Username); code(err) != "not_found" {
		t.Fatalf("a blocked profile reads not_found: %v", err)
	}
}
