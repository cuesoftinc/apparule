package sweep

import (
	"testing"
	"time"
)

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
