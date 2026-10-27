package ratelimit

import (
	"testing"
	"time"
)

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
