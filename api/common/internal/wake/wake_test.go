package wake

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"
)

func TestSettleWaitsForTheAnswer(t *testing.T) {
	var method, path, auth string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		method, path, auth = r.Method, r.URL.Path, r.Header.Get("Authorization")
		time.Sleep(100 * time.Millisecond) // the target settles before it answers
		_, _ = w.Write([]byte(`{"caught_up":true}`))
	}))
	defer srv.Close()

	w := New()
	w.idTokens = false
	start := time.Now()
	if err := w.Settle(context.Background(), srv.URL+"/", "test"); err != nil {
		t.Fatal(err)
	}
	if method != http.MethodPost || path != "/internal/settle" || auth != "" {
		t.Fatalf("called %s %s auth=%q; want an unsigned POST /internal/settle", method, path, auth)
	}
	if time.Since(start) < 100*time.Millisecond {
		t.Fatal("Settle returned before the target answered")
	}
}

func TestSettleSignsWithAnIDTokenForTheTarget(t *testing.T) {
	var gotAudience, gotFlavor string
	meta := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAudience, gotFlavor = r.URL.Query().Get("audience"), r.Header.Get("Metadata-Flavor")
		_, _ = w.Write([]byte("signed-token\n"))
	}))
	defer meta.Close()
	var auth string
	srv := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { auth = r.Header.Get("Authorization") }))
	defer srv.Close()

	w := New()
	w.idTokens, w.identity = true, meta.URL
	if err := w.Settle(context.Background(), srv.URL, "test"); err != nil {
		t.Fatal(err)
	}
	if auth != "Bearer signed-token" || gotAudience != srv.URL || gotFlavor != "Google" {
		t.Fatalf("auth=%q audience=%q flavor=%q", auth, gotAudience, gotFlavor)
	}
}

func TestSettleReportsAFailedTarget(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer srv.Close()
	w := New()
	w.idTokens = false
	if err := w.Settle(context.Background(), srv.URL, "test"); err == nil {
		t.Fatal("Settle on a 503 = nil; want an error")
	}
}

func TestSettleWithoutATargetDoesNothing(t *testing.T) {
	w := New()
	w.idTokens = false
	if err := w.Settle(context.Background(), "", "nothing configured"); err != nil {
		t.Fatal(err)
	}
}

func TestSettleAllCallsEachDistinctTargetOnceAndWaitsForAll(t *testing.T) {
	var hits atomic.Int32
	slow := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		time.Sleep(100 * time.Millisecond)
		hits.Add(1)
	}))
	defer slow.Close()
	other := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) { hits.Add(1) }))
	defer other.Close()

	w := New()
	w.idTokens = false
	w.SettleAll(context.Background(), "test", slow.URL, "", other.URL, slow.URL)
	if hits.Load() != 2 {
		t.Fatalf("hits = %d; want 2 once SettleAll returns", hits.Load())
	}
}
