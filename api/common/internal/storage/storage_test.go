package storage

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"
)

type countingStore struct {
	Store
	calls int
	fail  bool
}

func (s *countingStore) SignedURL(_ context.Context, key string, _ time.Duration) (string, error) {
	s.calls++
	if s.fail {
		return "", errors.New("sign failed")
	}
	return fmt.Sprintf("https://signed.test/%s?n=%d", key, s.calls), nil
}

func TestSignCacheReusesFreshURL(t *testing.T) {
	ctx := context.Background()
	inner := &countingStore{}
	c := cached(inner).(*signCache)

	a, _ := c.SignedURL(ctx, "media/p/0.jpg", time.Hour)
	b, _ := c.SignedURL(ctx, "media/p/0.jpg", time.Hour)
	if a != b || inner.calls != 1 {
		t.Fatalf("want one signing reused, got %d calls (%q, %q)", inner.calls, a, b)
	}

	if _, _ = c.SignedURL(ctx, "media/p/0.jpg", time.Minute); inner.calls != 2 {
		t.Fatalf("a different ttl must sign again, got %d calls", inner.calls)
	}

	k := signKey{"media/p/0.jpg", time.Hour}
	c.urls[k] = signedURL{url: a, expires: time.Now().Add(29 * time.Minute)}
	if u, _ := c.SignedURL(ctx, "media/p/0.jpg", time.Hour); u == a || inner.calls != 3 {
		t.Fatalf("a URL past half its life must be re-signed, got %d calls", inner.calls)
	}
}

func TestSignCacheDoesNotCacheErrors(t *testing.T) {
	ctx := context.Background()
	inner := &countingStore{fail: true}
	c := cached(inner).(*signCache)

	if _, err := c.SignedURL(ctx, "k", time.Hour); err == nil {
		t.Fatal("want the signing error")
	}
	inner.fail = false
	if u, err := c.SignedURL(ctx, "k", time.Hour); err != nil || u == "" || inner.calls != 2 {
		t.Fatalf("a failed signing must not be cached: %q %v calls=%d", u, err, inner.calls)
	}
}

func TestSignCacheStaysBounded(t *testing.T) {
	ctx := context.Background()
	c := cached(&countingStore{}).(*signCache)
	for i := range maxSigned + 5 {
		if _, err := c.SignedURL(ctx, fmt.Sprintf("k%d", i), time.Hour); err != nil {
			t.Fatal(err)
		}
	}
	if len(c.urls) > maxSigned {
		t.Fatalf("cache holds %d entries, cap is %d", len(c.urls), maxSigned)
	}
}
