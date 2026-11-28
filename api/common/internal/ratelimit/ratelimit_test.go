package ratelimit

import (
	"context"
	"net"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/alicebob/miniredis/v2"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

func TestConcurrentTakeEnforcesLimit(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatal(err)
	}
	defer mr.Close()

	host, port, err := net.SplitHostPort(mr.Addr())
	if err != nil {
		t.Fatal(err)
	}
	l := New(config.Redis{Host: host, Port: port, KeyPrefix: "concurrency"})
	defer l.Close()

	const limit = 10
	const requests = 50
	start := make(chan struct{})
	var accepted atomic.Int32
	var wg sync.WaitGroup
	for i := 0; i < requests; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			ok, _ := l.Take(context.Background(), "acct-1", 1, Rule{Name: "concurrent", Max: limit, Window: time.Minute})
			if ok {
				accepted.Add(1)
			}
		}()
	}
	close(start)
	wg.Wait()
	if got := accepted.Load(); got != limit {
		t.Fatalf("accepted = %d, want %d", got, limit)
	}
}

func TestWindowKey(t *testing.T) {
	now := time.Unix(1_800_000_090, 0)
	rule := Rule{Name: "captures_min", Max: 10, Window: time.Minute}
	tests := []struct {
		name   string
		prefix string
		want   string
	}{
		{"prefixed", "apparule", "apparule:rl:captures_min:acct-1:30000001"},
		{"no prefix", "", "rl:captures_min:acct-1:30000001"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			l := &Limiter{prefix: tt.prefix}
			if got := l.windowKey(rule, "acct-1", now); got != tt.want {
				t.Fatalf("key = %q, want %q", got, tt.want)
			}
		})
	}
}

// TestTakeTwoRulesDayRefusalSparesMinute proves that when the day rule
// refuses, the minute counter is not incremented (one refusal costs nothing).
func TestTakeTwoRulesDayRefusalSparesMinute(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatal(err)
	}
	defer mr.Close()
	host, port, err := net.SplitHostPort(mr.Addr())
	if err != nil {
		t.Fatal(err)
	}
	l := New(config.Redis{Host: host, Port: port, KeyPrefix: "tworulespare"})
	defer l.Close()
	ctx := context.Background()

	minute := Rule{Name: "capture-min", Max: 1, Window: time.Minute}
	day := Rule{Name: "capture-day", Max: 1, Window: 24 * time.Hour}
	key := "acct-spare"

	// Drain only the day rule; the minute rule still has room.
	if ok, _ := l.Take(ctx, key, 1, day); !ok {
		t.Fatal("first day take should succeed")
	}

	// Minute has room, day refuses: the combined take must refuse and must
	// not spend the minute quota.
	ok, wait := l.Take(ctx, key, 1, minute, day)
	if ok {
		t.Fatal("expected refusal when the day rule is at its limit")
	}
	if wait <= 0 {
		t.Fatal("refusal wait must be greater than zero")
	}
	if wait > day.Window {
		t.Fatalf("wait %v exceeds the day window %v", wait, day.Window)
	}

	// The minute counter was not spent: a minute-only take still succeeds...
	if ok, _ := l.Take(ctx, key, 1, minute); !ok {
		t.Fatal("minute quota should still be available after a day-only refusal")
	}
	// ...and is now exhausted.
	if ok, _ := l.Take(ctx, key, 1, minute); ok {
		t.Fatal("minute quota should now be exhausted")
	}
}

// TestTakeTwoRulesWaitIsLonger proves that a combined refusal returns the
// longer of the two applicable waits, that the wait is greater than zero,
// and that it does not exceed the relevant rule window.
func TestTakeTwoRulesWaitIsLonger(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatal(err)
	}
	defer mr.Close()
	host, port, err := net.SplitHostPort(mr.Addr())
	if err != nil {
		t.Fatal(err)
	}
	l := New(config.Redis{Host: host, Port: port, KeyPrefix: "tworulewait"})
	defer l.Close()
	ctx := context.Background()

	minute := Rule{Name: "capture-min", Max: 1, Window: time.Minute}
	day := Rule{Name: "capture-day", Max: 1, Window: 24 * time.Hour}
	key := "acct-wait"

	// Drain both rules; every take now refuses, so the counters stay stable.
	if ok, _ := l.Take(ctx, key, 1, minute); !ok {
		t.Fatal("first minute take should succeed")
	}
	if ok, _ := l.Take(ctx, key, 1, day); !ok {
		t.Fatal("first day take should succeed")
	}

	_, waitM := l.Take(ctx, key, 1, minute)
	_, waitD := l.Take(ctx, key, 1, day)
	if waitM <= 0 || waitD <= 0 {
		t.Fatal("individual refusal waits must be greater than zero")
	}

	// The combined refusal waits the longer of the two applicable waits.
	_, waitBoth := l.Take(ctx, key, 1, minute, day)
	if waitBoth <= 0 {
		t.Fatal("combined refusal wait must be greater than zero")
	}
	if waitBoth > day.Window {
		t.Fatalf("wait %v exceeds the day window %v", waitBoth, day.Window)
	}
	want := waitM
	if waitD > want {
		want = waitD
	}
	if waitBoth != want {
		t.Fatalf("combined wait %v != longer of %v and %v", waitBoth, waitM, waitD)
	}
}
