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
