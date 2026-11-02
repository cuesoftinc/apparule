package handler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
)

const testWeb = "https://app.example.com"

type fakeAuthService struct {
	handoffErr error
	revoked    []string
	challenge  string
}

func (f *fakeAuthService) SignInGoogle(context.Context, *auth.Identity) (string, error) {
	return uuid.NewString(), nil
}

func (f *fakeAuthService) CreateSSOHandoff(_ context.Context, _, challenge string) (string, string, error) {
	f.challenge = challenge
	return strings.Repeat("b", 43), strings.Repeat("c", 43), nil
}

func (f *fakeAuthService) RedeemSSOHandoff(context.Context, string, string, string) (string, error) {
	if f.handoffErr != nil {
		return "", f.handoffErr
	}
	return "session-token", nil
}

func (f *fakeAuthService) RevokeSession(_ context.Context, id string) error {
	f.revoked = append(f.revoked, id)
	return nil
}

type fakeGoogle struct{}

func (fakeGoogle) AuthorizeURL(redirectURI, state, challenge string) string {
	return "https://accounts.example.test/auth?" + url.Values{"redirect_uri": {redirectURI}, "state": {state}, "code_challenge": {challenge}}.Encode()
}

func (fakeGoogle) ExchangeCode(context.Context, string, string, string) (*auth.Identity, error) {
	return &auth.Identity{Sub: "sub", Email: "a@example.com"}, nil
}

func testAuthHandler(svc *fakeAuthService) *AuthHandler {
	cfg := &config.Config{WebURL: testWeb, CORSOrigins: []string{testWeb, "https://second.example.com"}, AppReturnURLs: []string{"apparule://app"}}
	cfg.Auth = config.Auth{
		GoogleRedirectURI: "https://api.example.com/api/v1/auth/sso/google/callback",
		JWTSecret:         "secret", JWTAccessTTL: time.Hour,
		SessionCookieName: "sess", OAuthStateCookie: "state",
		StartSourceRate: 2, StartGlobalRate: 100, StartSourcePending: 10, StartGlobalPending: 100,
	}
	return NewAuthHandler(cfg, svc, ratelimit.NewMemorySSOStore(), fakeGoogle{})
}

func cookieNamed(rec *httptest.ResponseRecorder, name string) *http.Cookie {
	for _, c := range rec.Result().Cookies() {
		if c.Name == name {
			return c
		}
	}
	return nil
}

func TestGoogleLoginRedirectsWithStateCookie(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	rec := httptest.NewRecorder()
	h.GoogleLogin(rec, httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google?cv="+strings.Repeat("a", 43), nil))
	if rec.Code != http.StatusTemporaryRedirect {
		t.Fatalf("status = %d", rec.Code)
	}
	loc, err := url.Parse(rec.Header().Get("Location"))
	if err != nil || loc.Query().Get("code_challenge") == "" {
		t.Fatalf("location = %q", rec.Header().Get("Location"))
	}
	c := cookieNamed(rec, "state")
	if c == nil || c.Value != loc.Query().Get("state") || !c.HttpOnly || !c.Secure || c.MaxAge != 600 {
		t.Fatalf("state cookie = %+v", c)
	}
}

func TestGoogleLoginRejectsForeignReturnTo(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	rec := httptest.NewRecorder()
	h.GoogleLogin(rec, httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google?return_to=https://evil.example.com/x", nil))
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", rec.Code)
	}
}

func TestGoogleLoginAppReturnRequiresChallenge(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	rec := httptest.NewRecorder()
	h.GoogleLogin(rec, httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google?return_to=apparule://app", nil))
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", rec.Code)
	}
}

func TestGoogleCallbackHandsBackToApp(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	start := httptest.NewRecorder()
	h.GoogleLogin(start, httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google?return_to=apparule://app&cv="+strings.Repeat("a", 43), nil))
	if start.Code != http.StatusTemporaryRedirect {
		t.Fatalf("start status = %d", start.Code)
	}
	state := cookieNamed(start, "state").Value

	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google/callback?code=abc&state="+state, nil)
	req.AddCookie(&http.Cookie{Name: "state", Value: state})
	rec := httptest.NewRecorder()
	h.GoogleCallback(rec, req)
	if want := "apparule://app/auth/callback?handoff=" + strings.Repeat("b", 43); rec.Header().Get("Location") != want {
		t.Fatalf("location = %q, want %q", rec.Header().Get("Location"), want)
	}
}

func TestGoogleLoginRateLimitsPerSource(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	var last *httptest.ResponseRecorder
	for i := 0; i < 3; i++ {
		last = httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google", nil)
		req.RemoteAddr = "203.0.113.9:4000"
		h.GoogleLogin(last, req)
	}
	if last.Code != http.StatusTooManyRequests || last.Header().Get("Retry-After") != "60" {
		t.Fatalf("status = %d, retry-after = %q", last.Code, last.Header().Get("Retry-After"))
	}
}

func TestGoogleCallbackIssuesHandoff(t *testing.T) {
	svc := &fakeAuthService{}
	h := testAuthHandler(svc)
	start := httptest.NewRecorder()
	h.GoogleLogin(start, httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google?cv="+strings.Repeat("a", 43), nil))
	state := cookieNamed(start, "state").Value

	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/sso/google/callback?code=abc&state="+state, nil)
	req.AddCookie(&http.Cookie{Name: "state", Value: state})
	rec := httptest.NewRecorder()
	h.GoogleCallback(rec, req)
	if rec.Code != http.StatusFound {
		t.Fatalf("status = %d", rec.Code)
	}
	if want := testWeb + "/auth/callback?handoff=" + strings.Repeat("b", 43); rec.Header().Get("Location") != want {
		t.Fatalf("location = %q, want %q", rec.Header().Get("Location"), want)
	}
	if c := cookieNamed(rec, oauthHandoffCookie); c == nil || c.Value != strings.Repeat("c", 43) || !c.HttpOnly {
		t.Fatalf("handoff cookie = %+v", c)
	}
	if svc.challenge != strings.Repeat("a", 43) {
		t.Fatalf("challenge = %q", svc.challenge)
	}

	replay := httptest.NewRecorder()
	h.GoogleCallback(replay, req)
	if loc := replay.Header().Get("Location"); !strings.Contains(loc, "/signin?error=expired_state") {
		t.Fatalf("replayed state location = %q", loc)
	}
}

func TestGoogleCallbackStateErrors(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	tests := []struct {
		name   string
		target string
		cookie string
		want   string
	}{
		{"no cookie", "/cb?code=x&state=s", "", "missing_state"},
		{"mismatch", "/cb?code=x&state=s", "t", "invalid_state"},
		{"denied", "/cb?error=access_denied&state=s", "s", "access_denied"},
		{"no code", "/cb?state=s", "s", "missing_code"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tt.target, nil)
			if tt.cookie != "" {
				req.AddCookie(&http.Cookie{Name: "state", Value: tt.cookie})
			}
			rec := httptest.NewRecorder()
			h.GoogleCallback(rec, req)
			if loc := rec.Header().Get("Location"); !strings.Contains(loc, testWeb+"/signin?error="+tt.want) {
				t.Fatalf("location = %q", loc)
			}
		})
	}
}

func exchange(h *AuthHandler, body, contentType, origin string, cookie *http.Cookie) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/sso/exchange", strings.NewReader(body))
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	if origin != "" {
		req.Header.Set("Origin", origin)
	}
	if cookie != nil {
		req.AddCookie(cookie)
	}
	rec := httptest.NewRecorder()
	h.ExchangeSSOHandoff(rec, req)
	return rec
}

func TestExchangeBodyChannel(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	body := `{"handoff":"` + strings.Repeat("b", 43) + `","verifier":"` + strings.Repeat("v", 43) + `"}`
	rec := exchange(h, body, "application/json", testWeb, nil)
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"access_token":"session-token"`) {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	if c := cookieNamed(rec, "sess"); c == nil || c.Value != "session-token" || !c.HttpOnly || c.MaxAge != 3600 {
		t.Fatalf("session cookie = %+v", c)
	}
}

func TestExchangeRejectsBadRequests(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	good := `{"handoff":"` + strings.Repeat("b", 43) + `","verifier":"` + strings.Repeat("v", 43) + `"}`
	tests := []struct {
		name        string
		body, ctype string
		origin      string
		want        int
	}{
		{"wrong content type", good, "text/plain", testWeb, http.StatusBadRequest},
		{"unknown field", `{"handoff":"x","verifier":"y","extra":1}`, "application/json", testWeb, http.StatusBadRequest},
		{"two documents", good + good, "application/json", testWeb, http.StatusBadRequest},
		{"short handoff", `{"handoff":"x","verifier":"` + strings.Repeat("v", 43) + `"}`, "application/json", testWeb, http.StatusBadRequest},
		{"oversized", strings.Repeat("a", 5000), "application/json", testWeb, http.StatusRequestEntityTooLarge},
		{"foreign origin", good, "application/json", "https://evil.example.com", http.StatusUnauthorized},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if rec := exchange(h, tt.body, tt.ctype, tt.origin, nil); rec.Code != tt.want {
				t.Fatalf("status = %d, want %d: %s", rec.Code, tt.want, rec.Body)
			}
		})
	}
}

func TestExchangeCookieChannel(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{})
	cookie := &http.Cookie{Name: oauthHandoffCookie, Value: strings.Repeat("c", 43)}
	if rec := exchange(h, "", "", testWeb, cookie); rec.Code != http.StatusOK {
		t.Fatalf("web origin status = %d: %s", rec.Code, rec.Body)
	}
	rec := exchange(h, "", "", "https://second.example.com", cookie)
	if rec.Code != http.StatusUnauthorized || !strings.Contains(rec.Body.String(), "handoff_verifier_required") {
		t.Fatalf("secondary origin status = %d: %s", rec.Code, rec.Body)
	}
}

func TestExchangeInvalidHandoff(t *testing.T) {
	h := testAuthHandler(&fakeAuthService{handoffErr: auth.ErrHandoffInvalid})
	body := `{"handoff":"` + strings.Repeat("b", 43) + `","verifier":"` + strings.Repeat("v", 43) + `"}`
	if rec := exchange(h, body, "application/json", testWeb, nil); rec.Code != http.StatusUnauthorized || !strings.Contains(rec.Body.String(), "handoff_invalid") {
		t.Fatalf("status = %d: %s", rec.Code, rec.Body)
	}
}

func TestLogout(t *testing.T) {
	svc := &fakeAuthService{}
	h := testAuthHandler(svc)
	id := uuid.NewString()
	token, err := auth.IssueToken("secret", time.Hour, id, "a@example.com", 0, time.Now())
	if err != nil {
		t.Fatal(err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	h.Logout(rec, req)
	if rec.Code != http.StatusNoContent || len(svc.revoked) != 1 || svc.revoked[0] != id {
		t.Fatalf("bearer logout: status = %d revoked = %v", rec.Code, svc.revoked)
	}
	if c := cookieNamed(rec, "sess"); c == nil || c.MaxAge >= 0 {
		t.Fatalf("session cookie not cleared: %+v", c)
	}

	cross := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	cross.AddCookie(&http.Cookie{Name: "sess", Value: token})
	cross.Header.Set("Origin", "https://evil.example.com")
	rec = httptest.NewRecorder()
	h.Logout(rec, cross)
	if rec.Code != http.StatusForbidden || len(svc.revoked) != 1 {
		t.Fatalf("cross-site logout: status = %d revoked = %v", rec.Code, svc.revoked)
	}
}

func TestSourceIP(t *testing.T) {
	r := httptest.NewRequest(http.MethodGet, "/", nil)
	r.RemoteAddr = "[::ffff:192.0.2.1]:80"
	r.Header.Set("X-Forwarded-For", "198.51.100.7, 203.0.113.5")
	if ip, ok := sourceIP(r, 0); !ok || ip != "192.0.2.1" {
		t.Fatalf("direct = %q %v", ip, ok)
	}
	if ip, ok := sourceIP(r, 1); !ok || ip != "203.0.113.5" {
		t.Fatalf("one hop = %q %v", ip, ok)
	}
	if _, ok := sourceIP(r, 3); ok {
		t.Fatal("too few hops must be unattributed")
	}
}

func TestPKCEVerifierSyntax(t *testing.T) {
	if !isPKCEVerifier(strings.Repeat("a", 43)) || !isPKCEVerifier(strings.Repeat("a.~-_", 20)) {
		t.Fatal("valid verifier rejected")
	}
	if isPKCEVerifier(strings.Repeat("a", 42)) || isPKCEVerifier(strings.Repeat("a", 129)) || isPKCEVerifier(strings.Repeat("a", 42)+"+") {
		t.Fatal("invalid verifier accepted")
	}
}

func TestSourceBucketKeyGroupsIPv6By64(t *testing.T) {
	if sourceBucketKey("2001:db8:1:2::1") != sourceBucketKey("2001:db8:1:2:ffff::9") {
		t.Fatal("same /64 split into two buckets")
	}
	if sourceBucketKey("2001:db8:1:2::1") == sourceBucketKey("2001:db8:1:3::1") {
		t.Fatal("different /64s share a bucket")
	}
	if got := sourceBucketKey("203.0.113.9"); got != "203.0.113.9" {
		t.Fatalf("ipv4 key = %q", got)
	}
}
