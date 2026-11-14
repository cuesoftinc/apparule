package service_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/sweep"
)

// pendingSave runs a capture to pending_save and returns the session id.
func pendingSave(t *testing.T, e *env, p *service.Principal) string {
	ctx := context.Background()
	ready(e, t, p)
	started, err := e.s.CreateCapture(ctx, p, 168, "")
	if err != nil {
		t.Fatal(err)
	}
	front, side := "apparule/test/tmp/capture/s/1/front.jpg", "apparule/test/tmp/capture/s/1/side.jpg"
	e.store.objects[front], e.store.objects[side] = []byte("f"), []byte("s")
	e.deliver(t, kafka.EventCaptureUploaded, map[string]any{"ticket_id": claimsOf(t, started.Upload.Ticket).JTI, "account_id": p.AccountID,
		"session_id": started.ID, "poses": map[string]any{"front": image(front), "side": image(side)}}, e.s.OnCaptureUploaded)
	e.deliver(t, kafka.EventCaptureMeasured, map[string]any{"session_id": started.ID, "attempt": 1, "status": "measured", "method": "mediapipe_2d_v2",
		"thresholds_version": "qc-test", "poses": map[string]string{"front": "accepted", "side": "accepted"},
		"measurements": []map[string]any{{"name": "bust", "value_cm": 91.2, "confidence": 0.74}},
		"meta":         map[string]any{"height_suspect": false, "ms": 1800}}, e.s.OnCaptureMeasured)
	return started.ID
}

func (e *env) objectsUnder(sub string) (n int) {
	for k := range e.store.objects {
		if strings.Contains(k, sub) {
			n++
		}
	}
	return n
}

// onFirstCopy runs fn once, on the first Copy, with the pool probe still on.
func (e *env) onFirstCopy(fn func()) {
	inner, done := e.store.probe, false
	e.store.probe = func(op string) {
		inner(op)
		if op == "copy" && !done {
			done = true
			fn()
		}
	}
}

// A save whose second transaction fails (the session was deleted while the
// images were copying) leaves no copy behind.
func TestSaveSessionDropsCopiesWhenTheSessionVanishes(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")
	id := pendingSave(t, e, kiki)
	e.onFirstCopy(func() {
		e.system(t, func(ctx context.Context, tx pgx.Tx) error {
			_, err := tx.Exec(ctx, `DELETE FROM measurement_session WHERE id = $1`, id)
			return err
		})
	})
	if _, err := e.s.SaveSession(ctx, kiki, id); err == nil {
		t.Fatal("saving a deleted session must fail")
	}
	if n := e.objectsUnder("/captures/"); n != 0 {
		t.Fatalf("%d copied images left behind with no row pointing at them", n)
	}
}

// A save that lost a race to another save keeps the images the winner confirmed.
func TestSaveSessionKeepsCopiesAnotherSaveConfirmed(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")
	id := pendingSave(t, e, kiki)
	e.onFirstCopy(func() {
		if _, err := e.s.SaveSession(ctx, kiki, id); err != nil {
			t.Errorf("the winning save: %v", err)
		}
	})
	if _, err := e.s.SaveSession(ctx, kiki, id); code(err) != "invalid_transition" {
		t.Fatalf("the losing save: %v", err)
	}
	if n := e.objectsUnder("/captures/"); n != 2 {
		t.Fatalf("%d confirmed images left, want 2: the loser deleted the winner's copies", n)
	}
}

// The retention sweep removes saved images and attachments no row points at
// and keeps the ones that are referenced.
func TestRetentionSweepsOrphanedCopies(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	kiki := e.signIn(t, "uid-kiki", "kiki@example.com")
	id := pendingSave(t, e, kiki)
	if _, err := e.s.SaveSession(ctx, kiki, id); err != nil {
		t.Fatal(err)
	}
	e.store.objects["apparule/test/captures/ws/s/front.jpg"] = []byte("x")
	e.store.objects["apparule/test/attachments/o/m.jpg"] = []byte("x")
	sw := &sweep.Sweeper{DB: e.db, Store: e.store, Services: e.s, Now: time.Now}
	if err := sw.Retention(ctx); err != nil {
		t.Fatal(err)
	}
	for _, k := range []string{"apparule/test/captures/ws/s/front.jpg", "apparule/test/attachments/o/m.jpg"} {
		if _, ok := e.store.objects[k]; ok {
			t.Fatalf("orphan %s survived the sweep", k)
		}
	}
	if n := e.objectsUnder("/captures/"); n != 2 {
		t.Fatalf("%d referenced capture images left, want 2", n)
	}
}
