package handler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSettleGuard(t *testing.T) {
	const scheduler, uploads = "scheduler@example.com", "uploads@example.com"
	tests := []struct {
		name     string
		audience string
		invokers []string
		verifier *fakeVerifier
		want     int
	}{
		{"audience unset", "", []string{scheduler}, &fakeVerifier{}, http.StatusServiceUnavailable},
		{"no invoker configured", "https://svc", nil, &fakeVerifier{}, http.StatusServiceUnavailable},
		{"only blank invokers", "https://svc", []string{""}, &fakeVerifier{}, http.StatusServiceUnavailable},
		{"scheduler", "https://svc", []string{scheduler, uploads}, &fakeVerifier{claims: Claims{Email: scheduler, EmailVerified: true}}, http.StatusOK},
		{"uploads", "https://svc", []string{scheduler, uploads}, &fakeVerifier{claims: Claims{Email: uploads, EmailVerified: true}}, http.StatusOK},
		{"another account", "https://svc", []string{scheduler, uploads}, &fakeVerifier{claims: Claims{Email: "x@example.com", EmailVerified: true}}, http.StatusForbidden},
		{"unverified email", "https://svc", []string{scheduler, uploads}, &fakeVerifier{claims: Claims{Email: uploads}}, http.StatusForbidden},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := &Settle{Verifier: tt.verifier, Audience: tt.audience, Invokers: tt.invokers}
			h := s.Guard(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }))
			req := httptest.NewRequest(http.MethodPost, "/internal/settle", nil)
			req.Header.Set("Authorization", "Bearer t")
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tt.want {
				t.Fatalf("status = %d, want %d", rec.Code, tt.want)
			}
		})
	}
}

func TestSettleHandleAnswersWhetherItCaughtUp(t *testing.T) {
	for _, caughtUp := range []bool{true, false} {
		s := &Settle{Run: func(context.Context) bool { return caughtUp }}
		rec := httptest.NewRecorder()
		s.Handle(rec, httptest.NewRequest(http.MethodPost, "/internal/settle", nil))
		want := `"caught_up":false`
		if caughtUp {
			want = `"caught_up":true`
		}
		if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), want) {
			t.Fatalf("caughtUp=%v: %d %q; want 200 with %s", caughtUp, rec.Code, rec.Body.String(), want)
		}
	}
}
