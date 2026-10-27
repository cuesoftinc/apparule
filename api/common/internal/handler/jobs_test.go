package handler

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type fakeVerifier struct {
	claims Claims
	err    error
	gotAud string
}

func (f *fakeVerifier) Verify(_ context.Context, _, audience string) (Claims, error) {
	f.gotAud = audience
	return f.claims, f.err
}

func TestJobsGuard(t *testing.T) {
	const invoker = "scheduler@example.iam.gserviceaccount.com"
	tests := []struct {
		name     string
		audience string
		invoker  string
		header   string
		verifier *fakeVerifier
		want     int
	}{
		{"audience unset", "", invoker, "Bearer t", &fakeVerifier{}, http.StatusServiceUnavailable},
		{"invoker unset", "https://svc", "", "Bearer t", &fakeVerifier{}, http.StatusServiceUnavailable},
		{"no header", "https://svc", invoker, "", &fakeVerifier{}, http.StatusUnauthorized},
		{"not bearer", "https://svc", invoker, "Basic t", &fakeVerifier{}, http.StatusUnauthorized},
		{"bad token", "https://svc", invoker, "Bearer t", &fakeVerifier{err: errors.New("bad")}, http.StatusUnauthorized},
		{"wrong email", "https://svc", invoker, "Bearer t", &fakeVerifier{claims: Claims{Email: "x@example.com", EmailVerified: true}}, http.StatusForbidden},
		{"unverified email", "https://svc", invoker, "Bearer t", &fakeVerifier{claims: Claims{Email: invoker}}, http.StatusForbidden},
		{"invoker", "https://svc", invoker, "Bearer t", &fakeVerifier{claims: Claims{Email: invoker, EmailVerified: true}}, http.StatusOK},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			j := &Jobs{Verifier: tt.verifier, Audience: tt.audience, Invoker: tt.invoker}
			h := j.Guard(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }))
			req := httptest.NewRequest(http.MethodPost, "/internal/jobs/captures", nil)
			if tt.header != "" {
				req.Header.Set("Authorization", tt.header)
			}
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tt.want {
				t.Fatalf("status = %d, want %d", rec.Code, tt.want)
			}
			if tt.want == http.StatusOK && tt.verifier.gotAud != tt.audience {
				t.Fatalf("verified against %q, want %q", tt.verifier.gotAud, tt.audience)
			}
		})
	}
}
