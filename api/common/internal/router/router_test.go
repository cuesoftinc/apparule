package router

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/cuesoftinc/apparule/api/common/internal/handler"
)

type allowAll struct{}

func (allowAll) Verify(context.Context, string, string) (handler.Claims, error) {
	return handler.Claims{Email: "scheduler@example.com", EmailVerified: true}, nil
}

func TestInternalJobsRoute(t *testing.T) {
	tests := []struct {
		name     string
		path     string
		jobErr   error
		want     int
		wantBody string
		wantRuns int
	}{
		{"unknown job", "/internal/jobs/nope", nil, http.StatusNotFound, "", 0},
		{"known job", "/internal/jobs/captures", nil, http.StatusOK, `"job":"captures"`, 1},
		{"failing job", "/internal/jobs/captures", errors.New("boom"), http.StatusInternalServerError, "", 1},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runs := 0
			jobs := &handler.Jobs{
				Run: map[string]func(context.Context) error{
					"captures": func(context.Context) error { runs++; return tt.jobErr },
				},
				Verifier: allowAll{}, Audience: "https://svc", Invoker: "scheduler@example.com",
			}
			h := New(&handler.Handlers{}, nil, func(next http.Handler) http.Handler { return next }, nil,
				func(context.Context) error { return nil }, jobs, nil)
			req := httptest.NewRequest(http.MethodPost, tt.path, nil)
			req.Header.Set("Authorization", "Bearer t")
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tt.want {
				t.Fatalf("status = %d, want %d", rec.Code, tt.want)
			}
			if !strings.Contains(rec.Body.String(), tt.wantBody) {
				t.Fatalf("body = %q, want it to contain %q", rec.Body.String(), tt.wantBody)
			}
			if runs != tt.wantRuns {
				t.Fatalf("runs = %d, want %d", runs, tt.wantRuns)
			}
		})
	}
}

func TestInternalSettleRoute(t *testing.T) {
	const uploads = "uploads@example.com"
	tests := []struct {
		name    string
		email   string
		want    int
		wantRun int
	}{
		{"scheduler", "scheduler@example.com", http.StatusOK, 1},
		{"uploads", uploads, http.StatusOK, 1},
		{"someone else", "other@example.com", http.StatusForbidden, 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runs := 0
			settle := &handler.Settle{
				Run:      func(context.Context) bool { runs++; return true },
				Verifier: asEmail(tt.email), Audience: "https://svc", Invokers: []string{"scheduler@example.com", uploads},
			}
			h := New(&handler.Handlers{}, nil, func(next http.Handler) http.Handler { return next }, nil,
				func(context.Context) error { return nil }, &handler.Jobs{}, settle)
			req := httptest.NewRequest(http.MethodPost, "/internal/settle", nil)
			req.Header.Set("Authorization", "Bearer t")
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tt.want || runs != tt.wantRun {
				t.Fatalf("status = %d, runs = %d; want %d, %d", rec.Code, runs, tt.want, tt.wantRun)
			}
			if tt.want == http.StatusOK && !strings.Contains(rec.Body.String(), `"caught_up":true`) {
				t.Fatalf("body = %q; want it to say caught_up", rec.Body.String())
			}
		})
	}
}

type asEmail string

func (e asEmail) Verify(context.Context, string, string) (handler.Claims, error) {
	return handler.Claims{Email: string(e), EmailVerified: true}, nil
}
