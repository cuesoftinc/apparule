package ratelimit

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// ErrStateMiss is returned by Take when the OAuth state is unknown, used or expired.
var ErrStateMiss = errors.New("sso state not found")

// SSOStartLimits bound sign-in starts: SourceRate and GlobalRate per RateWindow,
// SourcePending and GlobalPending outstanding states per StateTTL.
type SSOStartLimits struct {
	RateWindow    time.Duration
	StateTTL      time.Duration
	SourceRate    int
	GlobalRate    int
	SourcePending int
	GlobalPending int
}

func (l SSOStartLimits) validate() error {
	if l.RateWindow <= 0 || l.StateTTL <= 0 || l.SourceRate <= 0 ||
		l.GlobalRate <= 0 || l.SourcePending <= 0 || l.GlobalPending <= 0 {
		return fmt.Errorf("ratelimit: invalid SSO start limits")
	}
	return nil
}

// SSOStore holds the pending OAuth state and meters sign-in starts. Unlike
// the usage limits it fails closed: a start the store cannot record is refused.
type SSOStore interface {
	Set(ctx context.Context, key string, v any, ttl time.Duration) error
	// Take reads and removes a value in one step.
	Take(ctx context.Context, key string, dst any) error
	AllowSSOStart(ctx context.Context, sourceHash, reservationID string, now time.Time, limits SSOStartLimits) (bool, error)
	ReleaseSSOStart(ctx context.Context, sourceHash, reservationID string) error
}

// UnattributedSource is the one shared bucket for callers with no usable address.
const UnattributedSource = "unattributed"

func sourceBucket(sourceHash string) string {
	if sourceHash == "" {
		return UnattributedSource
	}
	return sourceHash
}

// NewSSOStore is Redis-backed when a limiter exists, in-process otherwise.
func NewSSOStore(l *Limiter) SSOStore {
	if l == nil {
		return NewMemorySSOStore()
	}
	return &redisSSOStore{l: l}
}

type redisSSOStore struct{ l *Limiter }

func (s *redisSSOStore) key(parts ...string) string {
	k := "auth:sso"
	for _, p := range parts {
		k += ":" + p
	}
	if s.l.prefix == "" {
		return k
	}
	return s.l.prefix + ":" + k
}

func (s *redisSSOStore) Set(ctx context.Context, key string, v any, ttl time.Duration) error {
	b, err := json.Marshal(v)
	if err != nil {
		return fmt.Errorf("ratelimit: marshal: %w", err)
	}
	return s.l.client.Set(ctx, s.key("state", key), b, ttl).Err()
}

func (s *redisSSOStore) Take(ctx context.Context, key string, dst any) error {
	b, err := s.l.client.GetDel(ctx, s.key("state", key)).Bytes()
	if errors.Is(err, redis.Nil) {
		return ErrStateMiss
	}
	if err != nil {
		return err
	}
	return json.Unmarshal(b, dst)
}

var allowSSOStartScript = redis.NewScript(`
redis.call("ZREMRANGEBYSCORE", KEYS[1], "-inf", ARGV[1])
redis.call("ZREMRANGEBYSCORE", KEYS[2], "-inf", ARGV[1])
redis.call("ZREMRANGEBYSCORE", KEYS[3], "-inf", ARGV[2])
redis.call("ZREMRANGEBYSCORE", KEYS[4], "-inf", ARGV[2])

if redis.call("ZCARD", KEYS[1]) >= tonumber(ARGV[4])
	or redis.call("ZCARD", KEYS[2]) >= tonumber(ARGV[5])
	or redis.call("ZCARD", KEYS[3]) >= tonumber(ARGV[6])
	or redis.call("ZCARD", KEYS[4]) >= tonumber(ARGV[7]) then
	return 0
end

redis.call("ZADD", KEYS[1], ARGV[2], ARGV[10])
redis.call("ZADD", KEYS[2], ARGV[2], ARGV[10])
redis.call("ZADD", KEYS[3], ARGV[3], ARGV[10])
redis.call("ZADD", KEYS[4], ARGV[3], ARGV[10])
redis.call("PEXPIRE", KEYS[1], ARGV[8])
redis.call("PEXPIRE", KEYS[2], ARGV[8])
redis.call("PEXPIRE", KEYS[3], ARGV[9])
redis.call("PEXPIRE", KEYS[4], ARGV[9])
return 1
`)

var releaseSSOStartScript = redis.NewScript(`
for i = 1, #KEYS do
	redis.call("ZREM", KEYS[i], ARGV[1])
end
return 1
`)

// AllowSSOStart atomically reserves rate and pending-state capacity. An
// unattributed source shares one constant bucket rather than bypassing the
// per-source caps.
func (s *redisSSOStore) AllowSSOStart(ctx context.Context, sourceHash, reservationID string, now time.Time, limits SSOStartLimits) (bool, error) {
	if err := limits.validate(); err != nil {
		return false, err
	}
	source := sourceBucket(sourceHash)
	keys := []string{
		s.key("start", "rate", "source", source),
		s.key("start", "rate", "global"),
		s.key("start", "pending", "source", source),
		s.key("start", "pending", "global"),
	}
	result, err := allowSSOStartScript.Run(ctx, s.l.client, keys,
		now.Add(-limits.RateWindow).UnixMilli(),
		now.UnixMilli(),
		now.Add(limits.StateTTL).UnixMilli(),
		limits.SourceRate,
		limits.GlobalRate,
		limits.SourcePending,
		limits.GlobalPending,
		limits.RateWindow.Milliseconds(),
		limits.StateTTL.Milliseconds(),
		reservationID,
	).Int()
	if err != nil {
		return false, fmt.Errorf("ratelimit: reserve SSO start: %w", err)
	}
	return result == 1, nil
}

// ReleaseSSOStart frees consumed pending-state capacity without resetting the
// independent rate window.
func (s *redisSSOStore) ReleaseSSOStart(ctx context.Context, sourceHash, reservationID string) error {
	if reservationID == "" {
		return nil
	}
	keys := []string{
		s.key("start", "pending", "source", sourceBucket(sourceHash)),
		s.key("start", "pending", "global"),
	}
	if err := releaseSSOStartScript.Run(ctx, s.l.client, keys, reservationID).Err(); err != nil {
		return fmt.Errorf("ratelimit: release SSO start: %w", err)
	}
	return nil
}

// MemorySSOStore is the single-instance store used when Redis is not configured.
type MemorySSOStore struct {
	mu      sync.Mutex
	entries map[string]memoryEntry
	limiter memorySSOLimiter
	now     func() time.Time
}

type memoryEntry struct {
	value     []byte
	expiresAt time.Time
}

func NewMemorySSOStore() *MemorySSOStore {
	return &MemorySSOStore{entries: make(map[string]memoryEntry), now: time.Now}
}

func (m *MemorySSOStore) Set(ctx context.Context, key string, v any, ttl time.Duration) error {
	b, err := json.Marshal(v)
	if err != nil {
		return fmt.Errorf("ratelimit: marshal: %w", err)
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	now := m.now()
	for k, e := range m.entries {
		if now.After(e.expiresAt) {
			delete(m.entries, k)
		}
	}
	m.entries[key] = memoryEntry{value: b, expiresAt: now.Add(ttl)}
	return nil
}

func (m *MemorySSOStore) Take(ctx context.Context, key string, dst any) error {
	m.mu.Lock()
	e, ok := m.entries[key]
	delete(m.entries, key)
	live := ok && !m.now().After(e.expiresAt)
	m.mu.Unlock()
	if !live {
		return ErrStateMiss
	}
	return json.Unmarshal(e.value, dst)
}

func (m *MemorySSOStore) AllowSSOStart(ctx context.Context, sourceHash, reservationID string, now time.Time, limits SSOStartLimits) (bool, error) {
	if err := limits.validate(); err != nil {
		return false, err
	}
	if err := ctx.Err(); err != nil {
		return false, err
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.limiter.allow(sourceBucket(sourceHash), reservationID, now, limits), nil
}

func (m *MemorySSOStore) ReleaseSSOStart(ctx context.Context, sourceHash, reservationID string) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	m.limiter.release(sourceBucket(sourceHash), reservationID)
	return nil
}

type ssoReservation struct {
	id        string
	expiresAt time.Time
}

type sourceSSOReservations struct {
	rateExpires []time.Time
	pending     []ssoReservation
}

type memorySSOLimiter struct {
	sources       map[string]*sourceSSOReservations
	globalRate    []ssoReservation
	globalPending []ssoReservation
}

func (l *memorySSOLimiter) allow(source, reservationID string, now time.Time, limits SSOStartLimits) bool {
	l.prune(now)
	reservations := l.sources[source]
	if reservations == nil {
		reservations = &sourceSSOReservations{}
		l.sources[source] = reservations
	}

	sourceLimited := len(reservations.rateExpires) >= limits.SourceRate ||
		len(reservations.pending) >= limits.SourcePending
	if sourceLimited || len(l.globalRate) >= limits.GlobalRate || len(l.globalPending) >= limits.GlobalPending {
		if len(reservations.rateExpires) == 0 && len(reservations.pending) == 0 {
			delete(l.sources, source)
		}
		return false
	}

	rateExpiry := now.Add(limits.RateWindow)
	pendingExpiry := now.Add(limits.StateTTL)
	reservations.rateExpires = append(reservations.rateExpires, rateExpiry)
	reservations.pending = append(reservations.pending, ssoReservation{id: reservationID, expiresAt: pendingExpiry})
	l.globalRate = append(l.globalRate, ssoReservation{expiresAt: rateExpiry})
	l.globalPending = append(l.globalPending, ssoReservation{id: reservationID, expiresAt: pendingExpiry})
	return true
}

func (l *memorySSOLimiter) release(source, reservationID string) {
	if reservations := l.sources[source]; reservations != nil {
		reservations.pending = removeSSOReservation(reservations.pending, reservationID)
		if len(reservations.rateExpires) == 0 && len(reservations.pending) == 0 {
			delete(l.sources, source)
		}
	}
	l.globalPending = removeSSOReservation(l.globalPending, reservationID)
}

func (l *memorySSOLimiter) prune(now time.Time) {
	if l.sources == nil {
		l.sources = make(map[string]*sourceSSOReservations)
	}
	l.globalRate = pruneSSOReservations(l.globalRate, now)
	l.globalPending = pruneSSOReservations(l.globalPending, now)
	for source, reservations := range l.sources {
		reservations.rateExpires = pruneTimes(reservations.rateExpires, now)
		reservations.pending = pruneSSOReservations(reservations.pending, now)
		if len(reservations.rateExpires) == 0 && len(reservations.pending) == 0 {
			delete(l.sources, source)
		}
	}
}

func pruneSSOReservations(reservations []ssoReservation, now time.Time) []ssoReservation {
	firstLive := 0
	for firstLive < len(reservations) && !reservations[firstLive].expiresAt.After(now) {
		firstLive++
	}
	return reservations[firstLive:]
}

func removeSSOReservation(reservations []ssoReservation, id string) []ssoReservation {
	for i := range reservations {
		if reservations[i].id == id {
			return append(reservations[:i], reservations[i+1:]...)
		}
	}
	return reservations
}

func pruneTimes(times []time.Time, now time.Time) []time.Time {
	firstLive := 0
	for firstLive < len(times) && !times[firstLive].After(now) {
		firstLive++
	}
	return times[firstLive:]
}
