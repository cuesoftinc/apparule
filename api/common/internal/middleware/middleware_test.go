package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/google/uuid"
)

func captureRequestLog(t *testing.T, h http.Handler, req *http.Request) map[string]any {
	t.Helper()
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&logs, nil)))
	t.Cleanup(func() { slog.SetDefault(previous) })

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	var record map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(logs.Bytes()), &record); err != nil {
		t.Fatalf("request log is not JSON: %q (%v)", logs.String(), err)
	}
	return record
}

func TestLoggerAuthenticatedMatchedRoute(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/sessions/{id}", MatchServeMuxPattern(mux, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := WithPrincipal(r.Context(), &repository.Principal{
			AccountID: "account-123",
			Email:     "private@example.com",
		})
		ctx = setLogAccount(ctx, "account-123")
		r = r.WithContext(ctx)
		w.WriteHeader(http.StatusOK)
	})))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sessions/session-456", nil)
	req.Header.Set("Authorization", "Bearer secret-token")
	record := captureRequestLog(t, Logger(mux), req)

	if got := record["account_id"]; got != "account-123" {
		t.Fatalf("account_id = %v, want account-123", got)
	}
	if got := record["route"]; got != "GET /api/v1/sessions/{id}" {
		t.Fatalf("route = %v, want GET /api/v1/sessions/{id}", got)
	}
	if got := record["path"]; got != "/api/v1/sessions/session-456" {
		t.Fatalf("path = %v, want raw path preserved", got)
	}

	for _, sensitive := range []string{"private@example.com", "secret-token", "Authorization", "Bearer"} {
		if strings.Contains(string(mustMarshalLog(t, record)), sensitive) {
			t.Fatalf("request log contains sensitive value %q", sensitive)
		}
	}
}

func TestLoggerAnonymousRequest(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("GET /health", http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// The health route is intentionally excluded from request logging.
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&logs, nil)))
	t.Cleanup(func() { slog.SetDefault(previous) })

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	Logger(mux).ServeHTTP(httptest.NewRecorder(), req)
	if logs.Len() != 0 {
		t.Fatalf("health log = %q, want no request log", logs.String())
	}

	mux2 := http.NewServeMux()
	mux2.Handle("GET /api/v1/public/{id}", http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	record := captureRequestLog(t, Logger(MatchServeMuxPattern(mux2, mux2)), httptest.NewRequest(http.MethodGet, "/api/v1/public/resource-789", nil))
	if _, ok := record["account_id"]; ok {
		t.Fatalf("anonymous request log fabricated account_id: %v", record["account_id"])
	}
	if got := record["route"]; got != "GET /api/v1/public/{id}" {
		t.Fatalf("route = %v, want GET /api/v1/public/{id}", got)
	}
}

func TestLoggerUnmatchedRoute(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/sessions/{id}", http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	record := captureRequestLog(t, Logger(mux), httptest.NewRequest(http.MethodGet, "/api/v1/unknown", nil))
	if got := record["route"]; got != "unmatched" {
		t.Fatalf("route = %v, want unmatched", got)
	}
	if got := record["path"]; got != "/api/v1/unknown" {
		t.Fatalf("path = %v, want /api/v1/unknown", got)
	}
}

func TestLoggerWrongMethodLogsUnmatched(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/sessions/{id}", http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	record := captureRequestLog(t, Logger(mux), httptest.NewRequest(http.MethodPost, "/api/v1/sessions/1", nil))
	if got := record["route"]; got != "unmatched" {
		t.Fatalf("route = %v, want unmatched", got)
	}
}

func TestRequestLineLevelFollowsTheStatus(t *testing.T) {
	prev := slog.Default()
	t.Cleanup(func() { slog.SetDefault(prev) })
	cases := []struct {
		method string
		status int
		want   string
	}{
		{http.MethodGet, http.StatusOK, "INFO"},
		{http.MethodPost, http.StatusNoContent, "INFO"},
		{http.MethodGet, http.StatusFound, "INFO"},
		{http.MethodOptions, http.StatusNoContent, "DEBUG"},
		{http.MethodOptions, http.StatusForbidden, "WARN"},
		{http.MethodGet, http.StatusUnauthorized, "WARN"},
		{http.MethodGet, http.StatusNotFound, "WARN"},
		{http.MethodPost, http.StatusInternalServerError, "ERROR"},
		{http.MethodGet, http.StatusBadGateway, "ERROR"},
	}
	for _, c := range cases {
		var out bytes.Buffer
		slog.SetDefault(slog.New(slog.NewJSONHandler(&out, &slog.HandlerOptions{Level: slog.LevelDebug})))
		h := Logger(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(c.status) }))
		h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(c.method, "/api/v1/things", nil))
		var line struct {
			Level  string `json:"level"`
			Msg    string `json:"msg"`
			Status int    `json:"status"`
		}
		if err := json.Unmarshal(out.Bytes(), &line); err != nil {
			t.Fatalf("%s %d: request line is not one JSON record: %v", c.method, c.status, err)
		}
		if line.Msg != "request" || line.Status != c.status || line.Level != c.want {
			t.Fatalf("%s %d: got level %s msg %q status %d, want level %s", c.method, c.status, line.Level, line.Msg, line.Status, c.want)
		}
	}
}

func TestHealthChecksWriteNoRequestLine(t *testing.T) {
	prev := slog.Default()
	t.Cleanup(func() { slog.SetDefault(prev) })
	var out bytes.Buffer
	slog.SetDefault(slog.New(slog.NewJSONHandler(&out, &slog.HandlerOptions{Level: slog.LevelDebug})))
	h := Logger(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusServiceUnavailable) }))
	for _, path := range []string{"/health", "/ready"} {
		h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, path, nil))
	}
	if out.Len() != 0 {
		t.Fatalf("health checks wrote request lines: %q", out.String())
	}
}

func mustMarshalLog(t *testing.T, record map[string]any) []byte {
	t.Helper()
	b, err := json.Marshal(record)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

type testSessions struct {
	principal *repository.Principal
	err       error
}

func (s testSessions) ResolveSession(context.Context, *auth.Claims) (*repository.Principal, error) {
	return s.principal, s.err
}

func testAuthConfig() *config.Config {
	cfg := &config.Config{}
	cfg.WebURL = "https://app.example.com"
	cfg.Auth.JWTSecret = "test-session-secret"
	cfg.Auth.SessionCookieName = "apparule_session"
	return cfg
}

func TestAuthenticateSuspendedAccountLogsAccountID(t *testing.T) {
	cfg := testAuthConfig()
	accountID := uuid.NewString()
	token, err := auth.IssueToken(cfg.Auth.JWTSecret, time.Hour, accountID, "private@example.com", 1, time.Now())
	if err != nil {
		t.Fatal(err)
	}

	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/me", http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("suspended account must not reach the leaf handler")
	}))
	authHandler := Authenticate(cfg, testSessions{principal: &repository.Principal{
		AccountID: accountID,
		Email:     "private@example.com",
		Suspended: true,
	}})(mux)
	h := Logger(MatchServeMuxPattern(mux, authHandler))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	record := captureRequestLogResult(t, h, req)

	if record.status != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", record.status)
	}
	if got := record.body["account_id"]; got != accountID {
		t.Fatalf("account_id = %v, want %s", got, accountID)
	}
	if got := record.body["route"]; got != "GET /api/v1/me" {
		t.Fatalf("route = %v, want GET /api/v1/me", got)
	}
	assertNoSensitiveLogValues(t, record.body, "private@example.com", token, "apparule_session", "cookie-secret", "password")
}

func TestAuthenticateAndAuthorizationRejectLogsAccountID(t *testing.T) {
	cfg := testAuthConfig()
	accountID := uuid.NewString()
	token, err := auth.IssueToken(cfg.Auth.JWTSecret, time.Hour, accountID, "private@example.com", 1, time.Now())
	if err != nil {
		t.Fatal(err)
	}

	leaf := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		p := PrincipalFrom(r.Context())
		if p == nil || p.AccountID != accountID {
			t.Fatalf("principal = %#v, want account %s", p, accountID)
		}
		w.WriteHeader(http.StatusForbidden)
	})
	mux := http.NewServeMux()
	mux.Handle("GET /api/v1/sessions/{id}", leaf)
	authHandler := Authenticate(cfg, testSessions{principal: &repository.Principal{
		AccountID: accountID,
		Email:     "private@example.com",
	}})(mux)
	h := Logger(MatchServeMuxPattern(mux, authHandler))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sessions/session-456", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Cookie", "apparule_session=cookie-secret")
	record := captureRequestLogResult(t, h, req)

	if record.status != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", record.status)
	}
	if got := record.body["account_id"]; got != accountID {
		t.Fatalf("account_id = %v, want %s", got, accountID)
	}
	if got := record.body["route"]; got != "GET /api/v1/sessions/{id}" {
		t.Fatalf("route = %v, want GET /api/v1/sessions/{id}", got)
	}
	assertNoSensitiveLogValues(t, record.body, "private@example.com", token, "cookie-secret", "apparule_session", "password")
}

type requestLogResult struct {
	status int
	body   map[string]any
}

func captureRequestLogResult(t *testing.T, h http.Handler, req *http.Request) requestLogResult {
	t.Helper()
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&logs, nil)))
	t.Cleanup(func() { slog.SetDefault(previous) })

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	var record map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(logs.Bytes()), &record); err != nil {
		t.Fatalf("request log is not JSON: %q (%v)", logs.String(), err)
	}
	return requestLogResult{status: rec.Code, body: record}
}

func assertNoSensitiveLogValues(t *testing.T, record map[string]any, values ...string) {
	t.Helper()
	b, err := json.Marshal(record)
	if err != nil {
		t.Fatal(err)
	}
	for _, sensitive := range values {
		if strings.Contains(string(b), sensitive) {
			t.Fatalf("request log contains sensitive value %q: %s", sensitive, b)
		}
	}
}
