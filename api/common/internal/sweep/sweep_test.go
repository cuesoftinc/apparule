package sweep

import (
	"bytes"
	"context"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
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
