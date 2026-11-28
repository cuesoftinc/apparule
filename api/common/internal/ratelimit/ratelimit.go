// Package ratelimit counts per-account usage in Redis (engineering.md §3).
// Losing Redis is survivable: limits fail open for the outage (§9.2), while
// idempotency and single-use tickets stay enforced in Postgres.
package ratelimit

import (
	"context"
	"crypto/tls"
	"fmt"
	"log/slog"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

type Limiter struct {
	client *redis.Client
	prefix string
}

// New returns nil when REDIS_HOST is unset (limits disabled).
func New(cfg config.Redis) *Limiter {
	if cfg.Host == "" {
		return nil
	}
	opts := &redis.Options{
		Addr:     cfg.Host + ":" + cfg.Port,
		Username: cfg.Username,
		Password: cfg.Password,
		DB:       cfg.DB,
	}
	if cfg.TLS {
		opts.TLSConfig = &tls.Config{MinVersion: tls.VersionTLS12}
	}
	return &Limiter{client: redis.NewClient(opts), prefix: cfg.KeyPrefix}
}

func (l *Limiter) Close() error {
	if l == nil {
		return nil
	}
	return l.client.Close()
}

// Rule is one fixed window: at most Max units per Window.
type Rule struct {
	Name   string
	Max    int64
	Window time.Duration
}

// Take adds cost to every rule's window for key, unless that would exceed
// one of them. It returns the longest wait when refused.
func (l *Limiter) Take(ctx context.Context, key string, cost int64, rules ...Rule) (ok bool, retryAfter time.Duration) {
	if l == nil {
		return true, 0
	}
	now := time.Now()
	keys := make([]string, 0, len(rules))
	args := make([]interface{}, 0, 1+len(rules)*3)
	args = append(args, cost)
	for _, r := range rules {
		keys = append(keys, l.windowKey(r, key, now))
		wait := r.Window - time.Duration(now.Unix()%int64(r.Window.Seconds()))*time.Second
		args = append(args, r.Max, int64(r.Window/time.Second), wait.Milliseconds())
	}
	waitMillis, err := takeScript.Run(ctx, l.client, keys, args...).Int64()
	if err != nil {
		slog.Warn("rate limiter unavailable; failing open", "error", err)
		return true, 0
	}
	if waitMillis > 0 {
		return false, time.Duration(waitMillis) * time.Millisecond
	}
	return true, 0
}

var takeScript = redis.NewScript(`
local cost = tonumber(ARGV[1])
local longest_wait = 0
for i = 1, #KEYS do
	local base = (i - 1) * 3
	local used = tonumber(redis.call("GET", KEYS[i]) or "0")
	local max = tonumber(ARGV[base + 2])
	local wait = tonumber(ARGV[base + 4])
	if used + cost > max and wait > longest_wait then
		longest_wait = wait
	end
end
if longest_wait > 0 then
	return longest_wait
end
for i = 1, #KEYS do
	local base = (i - 1) * 3
	redis.call("INCRBY", KEYS[i], cost)
	redis.call("EXPIRE", KEYS[i], tonumber(ARGV[base + 3]))
end
return 0
`)

// windowKey is <prefix>:rl:<rule>:<key>:<window index>.
func (l *Limiter) windowKey(r Rule, key string, now time.Time) string {
	k := fmt.Sprintf("rl:%s:%s:%d", r.Name, key, now.Unix()/int64(r.Window.Seconds()))
	if l.prefix == "" {
		return k
	}
	return l.prefix + ":" + k
}

func (l *Limiter) Ping(ctx context.Context) error {
	if l == nil {
		return nil
	}
	return l.client.Ping(ctx).Err()
}
