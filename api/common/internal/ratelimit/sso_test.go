package ratelimit

import (
	"context"
	"errors"
	"testing"
	"time"
)

func testLimits() SSOStartLimits {
	return SSOStartLimits{
		RateWindow:    time.Minute,
		StateTTL:      10 * time.Minute,
		SourceRate:    2,
		GlobalRate:    10,
		SourcePending: 3,
		GlobalPending: 3,
	}
}

func TestMemorySSOStartLimitsSourceAndGlobalCapacity(t *testing.T) {
	store := NewMemorySSOStore()
	ctx := context.Background()
	now := time.Unix(1_700_000_000, 0)
	limits := testLimits()

	for i, id := range []string{"a", "b"} {
		ok, err := store.AllowSSOStart(ctx, "source-a", id, now, limits)
		if err != nil || !ok {
			t.Fatalf("request %d allowed = %v, error = %v", i+1, ok, err)
		}
	}
	if ok, err := store.AllowSSOStart(ctx, "source-a", "over-rate", now, limits); err != nil || ok {
		t.Fatalf("per-source rate limit: allowed = %v, error = %v", ok, err)
	}
	if ok, err := store.AllowSSOStart(ctx, "source-b", "third", now, limits); err != nil || !ok {
		t.Fatalf("third global reservation allowed = %v, error = %v", ok, err)
	}
	if ok, err := store.AllowSSOStart(ctx, "source-c", "over-pending", now, limits); err != nil || ok {
		t.Fatalf("global pending limit: allowed = %v, error = %v", ok, err)
	}
	if err := store.ReleaseSSOStart(ctx, "source-a", "a"); err != nil {
		t.Fatal(err)
	}
	if ok, err := store.AllowSSOStart(ctx, "source-c", "after-release", now, limits); err != nil || !ok {
		t.Fatalf("reservation after release allowed = %v, error = %v", ok, err)
	}
	later := now.Add(limits.StateTTL + time.Nanosecond)
	if ok, err := store.AllowSSOStart(ctx, "source-c", "after-expiry", later, limits); err != nil || !ok {
		t.Fatalf("reservation after expiry allowed = %v, error = %v", ok, err)
	}
}

func TestMemorySSOStartUnattributedSourcesShareOneBucket(t *testing.T) {
	store := NewMemorySSOStore()
	ctx := context.Background()
	now := time.Unix(1_700_000_000, 0)
	limits := testLimits()

	for _, id := range []string{"a", "b"} {
		if ok, err := store.AllowSSOStart(ctx, "", id, now, limits); err != nil || !ok {
			t.Fatalf("allowed = %v, error = %v", ok, err)
		}
	}
	if ok, err := store.AllowSSOStart(ctx, UnattributedSource, "c", now, limits); err != nil || ok {
		t.Fatalf("unattributed bucket not shared: allowed = %v, error = %v", ok, err)
	}
}

func TestMemorySSOStartRejectsInvalidLimits(t *testing.T) {
	store := NewMemorySSOStore()
	if _, err := store.AllowSSOStart(context.Background(), "s", "id", time.Now(), SSOStartLimits{}); err == nil {
		t.Fatal("expected error for zero limits")
	}
}

func TestMemorySSOStoreTakeIsSingleUse(t *testing.T) {
	store := NewMemorySSOStore()
	ctx := context.Background()
	type rec struct{ V string }

	if err := store.Set(ctx, "k", rec{V: "x"}, time.Minute); err != nil {
		t.Fatal(err)
	}
	var got rec
	if err := store.Take(ctx, "k", &got); err != nil || got.V != "x" {
		t.Fatalf("take = %+v, error = %v", got, err)
	}
	if err := store.Take(ctx, "k", &got); !errors.Is(err, ErrStateMiss) {
		t.Fatalf("second take error = %v, want ErrStateMiss", err)
	}
}

func TestMemorySSOStoreTakeRejectsExpired(t *testing.T) {
	store := NewMemorySSOStore()
	clock := time.Unix(1_700_000_000, 0)
	store.now = func() time.Time { return clock }
	ctx := context.Background()

	if err := store.Set(ctx, "k", map[string]string{"a": "b"}, time.Minute); err != nil {
		t.Fatal(err)
	}
	clock = clock.Add(2 * time.Minute)
	var got map[string]string
	if err := store.Take(ctx, "k", &got); !errors.Is(err, ErrStateMiss) {
		t.Fatalf("expired take error = %v, want ErrStateMiss", err)
	}
}

func TestNewSSOStoreFallsBackToMemory(t *testing.T) {
	if _, ok := NewSSOStore(nil).(*MemorySSOStore); !ok {
		t.Fatal("expected in-memory store when no limiter is configured")
	}
}
