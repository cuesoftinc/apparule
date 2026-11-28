package sweep

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
)

func TestPaymentsSweepSkipsWhenPaystackIsNotConfigured(t *testing.T) {
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewTextHandler(&logs, nil)))
	t.Cleanup(func() { slog.SetDefault(previous) })

	job := &Sweeper{Services: &service.Services{Config: &config.Config{}}}
	if err := job.Payments(context.Background()); err != nil {
		t.Fatalf("unconfigured sweep should skip cleanly: %v", err)
	}
	if !strings.Contains(logs.String(), "payment verification sweep skipped") ||
		!strings.Contains(logs.String(), "Paystack is not configured") {
		t.Fatalf("missing clear skip diagnostic: %s", logs.String())
	}
}

func TestReconcileLooksPastBothEdgesButNotIntoTheFuture(t *testing.T) {
	now := time.Date(2026, 10, 19, 11, 2, 0, 0, time.UTC)
	from, to, lookupFrom, lookupTo := reconcileWindow(now)
	want := func(name string, got time.Time, hh, mm int) {
		if exp := time.Date(2026, 10, 19, hh, mm, 0, 0, time.UTC); !got.Equal(exp) {
			t.Errorf("%s = %s, want %s", name, got, exp)
		}
	}
	want("from", from, 9, 45)
	want("to", to, 10, 45)
	want("lookup from", lookupFrom, 9, 30)
	want("lookup to", lookupTo, 11, 0)
	if lookupTo.After(now) {
		t.Fatal("the lookup must not reach past now: the ledger can't have it yet")
	}
	// Consecutive runs cover every instant exactly once.
	nextFrom, _, _, _ := reconcileWindow(now.Add(time.Hour))
	if !nextFrom.Equal(to) {
		t.Fatalf("windows must tile: next from %s, this to %s", nextFrom, to)
	}
}

func TestAPassThatChangedNothingIsDebug(t *testing.T) {
	if got := idleLevel(0, 0, 0); got != slog.LevelDebug {
		t.Fatalf("idle pass level %v, want debug", got)
	}
	for _, counts := range [][]int64{{1, 0, 0}, {0, 2, 0}, {0, 0, 3}} {
		if got := idleLevel(counts...); got != slog.LevelInfo {
			t.Fatalf("pass %v level %v, want info", counts, got)
		}
	}
}

// fakeStore is a storage.Store whose Delete and List results are scripted by key and prefix.
type fakeStore struct {
	storage.Store
	objects    map[string][]storage.Object
	deleteErr  map[string]error
	listErr    map[string]error
	deleteCall []string
}

func (f *fakeStore) Prefix() string { return "p" }

func (f *fakeStore) List(_ context.Context, prefix string) ([]storage.Object, error) {
	if err := f.listErr[prefix]; err != nil {
		return nil, err
	}
	return f.objects[prefix], nil
}

func (f *fakeStore) Delete(_ context.Context, key string) error {
	f.deleteCall = append(f.deleteCall, key)
	return f.deleteErr[key]
}

func TestRejectedDeleteCountsAsFailureNotDeletion(t *testing.T) {
	now := time.Date(2026, 11, 27, 12, 0, 0, 0, time.UTC)
	old := now.Add(-48 * time.Hour)
	store := &fakeStore{
		objects: map[string][]storage.Object{
			"p/compute/": {{Key: "p/compute/ok", Created: old}, {Key: "p/compute/denied", Created: old}, {Key: "p/compute/fresh", Created: now}},
			"p/tmp/":     {{Key: "p/tmp/gone", Created: old}},
		},
		deleteErr: map[string]error{
			"p/compute/denied": errors.New("access denied"),
			"p/tmp/gone":       storage.ErrMissing,
			"row-key-bad":      errors.New("access denied"),
		},
	}
	job := &Sweeper{Store: store}
	counts := map[string]int64{}
	failures := job.sweepObjects(context.Background(), []string{"row-key-ok", "row-key-bad"}, now.Add(-24*time.Hour), counts)
	if failures != 2 {
		t.Fatalf("failures = %d, want 2", failures)
	}
	want := map[string]int64{"row_objects": 1, "objects": 1, "objects_absent": 1, "objects_failed": 2, "listings_failed": 0}
	for k, v := range want {
		if counts[k] != v {
			t.Errorf("counts[%s] = %d, want %d (all: %v)", k, counts[k], v, counts)
		}
	}
	for _, key := range store.deleteCall {
		if key == "p/compute/fresh" {
			t.Fatal("an object newer than the cutoff was deleted")
		}
	}
}

func TestListingErrorMarksTheSweepPartial(t *testing.T) {
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewTextHandler(&logs, nil)))
	t.Cleanup(func() { slog.SetDefault(previous) })

	now := time.Date(2026, 11, 27, 12, 0, 0, 0, time.UTC)
	store := &fakeStore{
		objects: map[string][]storage.Object{
			"p/tmp/": {{Key: "p/tmp/secret-photo.jpg", Created: now.Add(-48 * time.Hour)}},
		},
		listErr:   map[string]error{"p/compute/": errors.New("backend unavailable")},
		deleteErr: map[string]error{"p/tmp/secret-photo.jpg": errors.New("denied")},
	}
	job := &Sweeper{Store: store}
	counts := map[string]int64{}
	if failures := job.sweepObjects(context.Background(), nil, now.Add(-24*time.Hour), counts); failures != 2 {
		t.Fatalf("failures = %d, want 2 (one listing, one deletion)", failures)
	}
	if counts["listings_failed"] != 1 || counts["objects"] != 0 || counts["objects_failed"] != 1 {
		t.Fatalf("counts = %v", counts)
	}
	if strings.Contains(logs.String(), "secret-photo") {
		t.Fatalf("log names an object key: %s", logs.String())
	}
}

func TestOrphanListingErrorIsCountedAsFailure(t *testing.T) {
	store := &fakeStore{listErr: map[string]error{
		"p/captures/":    errors.New("backend unavailable"),
		"p/attachments/": errors.New("backend unavailable"),
	}}
	job := &Sweeper{Store: store}
	deleted, failures := job.sweepOrphans(context.Background(), time.Now())
	if deleted != 0 || failures != 2 {
		t.Fatalf("deleted %d failures %d, want 0 and 2", deleted, failures)
	}
}
