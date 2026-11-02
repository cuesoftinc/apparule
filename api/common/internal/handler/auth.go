package handler

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"net/netip"
	"net/url"
	"strings"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/middleware"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
)

const (
	oauthHandoffCookie = "apparule_oauth_handoff"
	ssoStateTTL        = 10 * time.Minute
	ssoStartRateWindow = time.Minute

	descStartFailed    = "Google sign-in could not be started. Please try again."
	descRateLimited    = "Too many sign-in attempts. Please wait and try again."
	descInvalidHandoff = "Google sign-in expired. Please try again."
	descInvalidRequest = "The sign-in request is invalid."
	descVerifierNeeded = "This origin must finish sign-in with its verifier: start login with ?cv=<challenge> and POST {handoff, verifier} as JSON to /api/v1/auth/sso/exchange."
	descExchangeFailed = "Google sign-in could not be completed. Please try again."
	descAccessDenied   = "Google sign-in was cancelled."
	descMissingState   = "Google sign-in state is missing. Please try again."
	descInvalidState   = "Google sign-in state is invalid. Please try again."
	descExpiredState   = "Google sign-in expired. Please try again."
	descMissingCode    = "Google did not return an authorization code. Please try again."
)

// ssoState is the stored payload of a pending sign-in. CodeVerifier is our
// PKCE secret for Google; Challenge is the client's commitment made before the
// redirect; ReturnTo was allowlisted at start and cannot change mid-flow.
type ssoState struct {
	CodeVerifier string `json:"code_verifier"`
	Challenge    string `json:"challenge,omitempty"`
	SourceHash   string `json:"source_hash,omitempty"`
	ReturnTo     string `json:"return_to,omitempty"`
}

// AuthService is the slice of the account service the sign-in endpoints need.
type AuthService interface {
	SignInGoogle(ctx context.Context, id *auth.Identity) (string, error)
	CreateSSOHandoff(ctx context.Context, accountID, challenge string) (bodyCode, cookieCode string, err error)
	RedeemSSOHandoff(ctx context.Context, code, channel, verifier string) (string, error)
	RevokeSession(ctx context.Context, accountID string) error
}

// GoogleClient is the Google side of the sign-in.
type GoogleClient interface {
	AuthorizeURL(redirectURI, state, codeChallenge string) string
	ExchangeCode(ctx context.Context, code, redirectURI, codeVerifier string) (*auth.Identity, error)
}

// AuthHandler serves Google sign-in, the handoff exchange and logout.
type AuthHandler struct {
	cfg    *config.Config
	svc    AuthService
	store  ratelimit.SSOStore
	google GoogleClient
}

func NewAuthHandler(cfg *config.Config, svc AuthService, store ratelimit.SSOStore, google GoogleClient) *AuthHandler {
	return &AuthHandler{cfg: cfg, svc: svc, store: store, google: google}
}

// GoogleLogin starts Google sign-in: GET /api/v1/auth/sso/google?cv=<challenge>.
func (h *AuthHandler) GoogleLogin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")

	returnTo := strings.TrimSpace(r.URL.Query().Get("return_to"))
	if returnTo != "" && !h.cfg.IsAllowedRedirectURL(returnTo) {
		h.startError(w, r, http.StatusBadRequest, "return_to_not_allowed",
			"return_to is not an allowed origin. Add its origin to CORS_ORIGINS.")
		return
	}
	// Another app can claim a custom scheme, so the app leg must bind a verifier.
	if h.cfg.IsAppReturnURL(returnTo) && !isURLToken(r.URL.Query().Get("cv")) {
		h.startError(w, r, http.StatusBadRequest, "challenge_required",
			"Sign-in from the app must start with ?cv=<challenge>.")
		return
	}

	state, err := randomURLToken()
	if err != nil {
		slog.ErrorContext(r.Context(), "google login: generate state", "error", err)
		h.startError(w, r, http.StatusInternalServerError, "sso_start_failed", descStartFailed)
		return
	}

	sourceHash := h.sourceHash(r)
	a := h.cfg.Auth
	allowed, err := h.store.AllowSSOStart(r.Context(), sourceHash, state, time.Now(), ratelimit.SSOStartLimits{
		RateWindow:    ssoStartRateWindow,
		StateTTL:      ssoStateTTL,
		SourceRate:    a.StartSourceRate,
		GlobalRate:    a.StartGlobalRate,
		SourcePending: a.StartSourcePending,
		GlobalPending: a.StartGlobalPending,
	})
	if err != nil {
		slog.ErrorContext(r.Context(), "google login: reserve start", "error", err)
		h.startError(w, r, http.StatusServiceUnavailable, "sso_unavailable", descStartFailed)
		return
	}
	if !allowed {
		w.Header().Set("Retry-After", "60")
		h.startError(w, r, http.StatusTooManyRequests, "rate_limited", descRateLimited)
		return
	}

	verifier, err := randomURLToken()
	if err != nil {
		h.release(r.Context(), sourceHash, state)
		slog.ErrorContext(r.Context(), "google login: generate verifier", "error", err)
		h.startError(w, r, http.StatusInternalServerError, "sso_start_failed", descStartFailed)
		return
	}

	// The endpoint is unauthenticated: only a canonical commitment is stored.
	challenge := r.URL.Query().Get("cv")
	if !isURLToken(challenge) {
		challenge = ""
	}
	rec := ssoState{CodeVerifier: verifier, Challenge: challenge, SourceHash: sourceHash, ReturnTo: returnTo}
	if err := h.store.Set(r.Context(), state, rec, ssoStateTTL); err != nil {
		h.release(r.Context(), sourceHash, state)
		slog.ErrorContext(r.Context(), "google login: store state", "error", err)
		h.startError(w, r, http.StatusServiceUnavailable, "sso_unavailable", descStartFailed)
		return
	}

	http.SetCookie(w, h.stateCookie(state, int(ssoStateTTL/time.Second)))
	http.Redirect(w, r, h.google.AuthorizeURL(h.cfg.Auth.GoogleRedirectURI, state, auth.PKCEChallengeS256(verifier)), http.StatusTemporaryRedirect)
}

// GoogleCallback finishes the Google leg: GET /api/v1/auth/sso/google/callback.
func (h *AuthHandler) GoogleCallback(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")

	stateCookie, err := r.Cookie(h.cfg.Auth.OAuthStateCookie)
	if err != nil || stateCookie.Value == "" {
		h.redirectError(w, r, "", "missing_state", descMissingState)
		return
	}
	queryState := r.URL.Query().Get("state")
	if queryState == "" || queryState != stateCookie.Value {
		h.redirectError(w, r, "", "invalid_state", descInvalidState)
		return
	}
	http.SetCookie(w, h.stateCookie("", -1))

	if oauthErr := r.URL.Query().Get("error"); oauthErr != "" {
		rec := h.discardState(r.Context(), queryState)
		code, description := "oauth_failed", descExchangeFailed
		if oauthErr == "access_denied" {
			code, description = "access_denied", descAccessDenied
		}
		slog.InfoContext(r.Context(), "google sign-in rejected by provider", "provider_error", oauthErr)
		h.redirectError(w, r, rec.ReturnTo, code, description)
		return
	}

	code := r.URL.Query().Get("code")
	if code == "" {
		rec := h.discardState(r.Context(), queryState)
		h.redirectError(w, r, rec.ReturnTo, "missing_code", descMissingCode)
		return
	}

	var rec ssoState
	if err := h.store.Take(r.Context(), queryState, &rec); err != nil || rec.CodeVerifier == "" {
		if err != nil && !errors.Is(err, ratelimit.ErrStateMiss) {
			slog.ErrorContext(r.Context(), "google callback: load state", "error", err)
		}
		h.redirectError(w, r, "", "expired_state", descExpiredState)
		return
	}
	h.release(r.Context(), rec.SourceHash, queryState)

	identity, err := h.google.ExchangeCode(r.Context(), code, h.cfg.Auth.GoogleRedirectURI, rec.CodeVerifier)
	if err != nil {
		slog.ErrorContext(r.Context(), "google callback: exchange code", "error", err)
		h.redirectError(w, r, rec.ReturnTo, "sso_failed", descExchangeFailed)
		return
	}
	accountID, err := h.svc.SignInGoogle(r.Context(), identity)
	if err != nil {
		slog.ErrorContext(r.Context(), "google callback: sign in", "error", err)
		h.redirectError(w, r, rec.ReturnTo, "sso_failed", descExchangeFailed)
		return
	}
	bodyCode, cookieCode, err := h.svc.CreateSSOHandoff(r.Context(), accountID, rec.Challenge)
	if err != nil {
		slog.ErrorContext(r.Context(), "google callback: create handoff", "error", err)
		h.redirectError(w, r, rec.ReturnTo, "sso_failed", descExchangeFailed)
		return
	}

	// Each channel has its own secret, so a captured callback URL cannot
	// redeem through the cookie path.
	http.SetCookie(w, h.cookie(oauthHandoffCookie, cookieCode, int((5*time.Minute)/time.Second)))
	http.Redirect(w, r, h.webBase(rec.ReturnTo)+"/auth/callback?handoff="+url.QueryEscape(bodyCode), http.StatusFound)
}

type exchangeRequest struct {
	Handoff  string `json:"handoff"`
	Verifier string `json:"verifier"`
}

type loginResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
}

// ExchangeSSOHandoff trades a one-time handoff for the session:
// POST /api/v1/auth/sso/exchange with {handoff, verifier}, or no body to
// redeem the HttpOnly handoff cookie.
func (h *AuthHandler) ExchangeSSOHandoff(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")

	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 4096))
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			writeError(w, http.StatusRequestEntityTooLarge, "request_too_large", descInvalidRequest, nil)
		} else {
			writeError(w, http.StatusBadRequest, "invalid_body", descInvalidRequest, nil)
		}
		return
	}

	var req exchangeRequest
	viaBody := len(body) > 0
	if viaBody {
		mediaType, params, mtErr := mime.ParseMediaType(r.Header.Get("Content-Type"))
		charset, hasCharset := params["charset"]
		if mtErr != nil || mediaType != "application/json" || (hasCharset && !strings.EqualFold(charset, "utf-8")) {
			writeError(w, http.StatusBadRequest, "invalid_body", descInvalidRequest, nil)
			return
		}
		if err := decodeSingleJSON(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid_body", descInvalidRequest, nil)
			return
		}
		if !isURLToken(req.Handoff) || !isPKCEVerifier(req.Verifier) {
			writeError(w, http.StatusBadRequest, "invalid_request", descInvalidRequest, nil)
			return
		}
	}

	if !h.exchangeAllowed(r, viaBody) {
		if !viaBody && h.secondaryOrigin(r) {
			writeError(w, http.StatusUnauthorized, "handoff_verifier_required", descVerifierNeeded, nil)
			return
		}
		writeError(w, http.StatusUnauthorized, "handoff_invalid", descInvalidHandoff, nil)
		return
	}

	code, channel := req.Handoff, auth.HandoffChannelBody
	if !viaBody {
		cookie, cerr := r.Cookie(oauthHandoffCookie)
		if cerr != nil || !isURLToken(cookie.Value) {
			writeError(w, http.StatusUnauthorized, "handoff_invalid", descInvalidHandoff, nil)
			return
		}
		code, channel = cookie.Value, auth.HandoffChannelCookie
	}

	token, err := h.svc.RedeemSSOHandoff(r.Context(), code, channel, req.Verifier)
	if errors.Is(err, auth.ErrHandoffInvalid) {
		writeError(w, http.StatusUnauthorized, "handoff_invalid", descInvalidHandoff, nil)
		return
	}
	if err != nil {
		slog.ErrorContext(r.Context(), "sso exchange", "error", err)
		writeError(w, http.StatusServiceUnavailable, "sso_unavailable", descExchangeFailed, nil)
		return
	}

	ttl := h.cfg.Auth.JWTAccessTTL
	http.SetCookie(w, h.cookie(oauthHandoffCookie, "", -1))
	http.SetCookie(w, h.cookie(h.cfg.Auth.SessionCookieName, token, int(ttl/time.Second)))
	writeJSON(w, http.StatusOK, loginResponse{AccessToken: token, ExpiresIn: int(ttl / time.Second)})
}

// Logout revokes the caller's sessions and clears the cookies:
// POST /api/v1/auth/logout.
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")

	token, fromCookie := bearerToken(r), false
	if token == "" {
		if c, err := r.Cookie(h.cfg.Auth.SessionCookieName); err == nil {
			token, fromCookie = c.Value, true
		}
	}
	if (fromCookie || token == "") && !middleware.CookieRequestAllowed(h.cfg, r) {
		writeError(w, http.StatusForbidden, "csrf_rejected", "The logout request is not allowed.", nil)
		return
	}
	http.SetCookie(w, h.cookie(h.cfg.Auth.SessionCookieName, "", -1))
	http.SetCookie(w, h.cookie(oauthHandoffCookie, "", -1))

	if token != "" {
		claims, err := auth.ParseToken(h.cfg.Auth.JWTSecret, token)
		if err == nil {
			if err := h.svc.RevokeSession(r.Context(), claims.Subject); err != nil {
				slog.ErrorContext(r.Context(), "logout: revoke session", "error", err)
				writeError(w, http.StatusServiceUnavailable, "logout_unavailable", "Logout is temporarily unavailable.", nil)
				return
			}
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

func bearerToken(r *http.Request) string {
	token, _ := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	return strings.TrimSpace(token)
}

// exchangeAllowed: the body channel is bound to the verifier and needs only an
// allowlisted Origin; the cookie channel carries an ambient credential and is
// pinned to the web app.
func (h *AuthHandler) exchangeAllowed(r *http.Request, viaBody bool) bool {
	if viaBody {
		origin := strings.TrimSpace(r.Header.Get("Origin"))
		return origin == "" || h.cfg.IsAllowedOrigin(origin)
	}
	return middleware.CookieRequestAllowed(h.cfg, r)
}

// secondaryOrigin reports an allowlisted Origin other than the web app.
func (h *AuthHandler) secondaryOrigin(r *http.Request) bool {
	origin := strings.TrimRight(strings.TrimSpace(r.Header.Get("Origin")), "/")
	return origin != "" && origin != h.cfg.WebURL && h.cfg.IsAllowedOrigin(origin)
}

func (h *AuthHandler) discardState(ctx context.Context, state string) ssoState {
	var rec ssoState
	if err := h.store.Take(ctx, state, &rec); err == nil {
		h.release(ctx, rec.SourceHash, state)
	}
	return rec
}

func (h *AuthHandler) release(ctx context.Context, sourceHash, reservationID string) {
	if err := h.store.ReleaseSSOStart(ctx, sourceHash, reservationID); err != nil {
		slog.WarnContext(ctx, "release sso pending capacity", "error", err)
	}
}

func (h *AuthHandler) stateCookie(value string, maxAge int) *http.Cookie {
	return h.cookie(h.cfg.Auth.OAuthStateCookie, value, maxAge)
}

func (h *AuthHandler) cookie(name, value string, maxAge int) *http.Cookie {
	c := &http.Cookie{
		Name:     name,
		Value:    value,
		Path:     "/",
		MaxAge:   maxAge,
		HttpOnly: true,
		Secure:   h.cfg.SecureCookies(),
		SameSite: http.SameSiteLaxMode,
	}
	if maxAge < 0 {
		c.Expires = time.Unix(1, 0).UTC()
	}
	return c
}

func (h *AuthHandler) webBase(returnTo string) string {
	if returnTo != "" {
		return strings.TrimRight(returnTo, "/")
	}
	return h.cfg.WebURL
}

// redirectError reports a failed sign-in to the page that started it.
func (h *AuthHandler) redirectError(w http.ResponseWriter, r *http.Request, returnTo, code, message string) {
	target := h.webBase(returnTo) + "/signin?error=" + url.QueryEscape(code) +
		"&error_description=" + url.QueryEscape(message) +
		"&message=" + url.QueryEscape(message)
	http.Redirect(w, r, target, http.StatusFound)
}

// startError answers a browser navigation with a redirect, anything else JSON.
func (h *AuthHandler) startError(w http.ResponseWriter, r *http.Request, status int, code, message string) {
	if strings.EqualFold(strings.TrimSpace(r.Header.Get("Sec-Fetch-Dest")), "document") ||
		strings.Contains(strings.ToLower(r.Header.Get("Accept")), "text/html") {
		h.redirectError(w, r, "", code, message)
		return
	}
	writeError(w, status, code, message, nil)
}

// sourceHash buckets sign-in starts by caller address; an unreadable address
// shares one bucket.
func (h *AuthHandler) sourceHash(r *http.Request) string {
	ip, ok := sourceIP(r, h.cfg.Auth.TrustedProxyHops)
	if !ok {
		return ratelimit.UnattributedSource
	}
	sum := sha256.Sum256([]byte(sourceBucketKey(ip)))
	return hex.EncodeToString(sum[:])[:16]
}

// sourceBucketKey keys an IPv6 source by its /64, the block one subscriber controls.
func sourceBucketKey(ip string) string {
	addr, err := netip.ParseAddr(ip)
	if err != nil || !addr.Is6() {
		return ip
	}
	prefix, err := addr.Prefix(64)
	if err != nil {
		return ip
	}
	return prefix.String()
}

// sourceIP reads the peer address, or the address TRUSTED_PROXY_HOPS proxies
// from the right in X-Forwarded-For.
func sourceIP(r *http.Request, hops int) (string, bool) {
	peer, ok := parseIP(r.RemoteAddr)
	if !ok {
		return "", false
	}
	if hops <= 0 {
		return peer.String(), true
	}
	parts := strings.Split(strings.Join(r.Header.Values("X-Forwarded-For"), ","), ",")
	if len(parts) < hops {
		return "", false
	}
	ip, ok := parseIP(strings.TrimSpace(parts[len(parts)-hops]))
	if !ok {
		return "", false
	}
	return ip.String(), true
}

func parseIP(raw string) (netip.Addr, bool) {
	if ap, err := netip.ParseAddrPort(raw); err == nil {
		return ap.Addr().Unmap().WithZone(""), true
	}
	addr, err := netip.ParseAddr(raw)
	if err != nil {
		return netip.Addr{}, false
	}
	return addr.Unmap().WithZone(""), true
}

func randomURLToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// isURLToken reports a canonical base64url SHA-256 digest or 32-byte token:
// exactly 43 characters of the base64url alphabet.
func isURLToken(s string) bool {
	if len(s) != 43 {
		return false
	}
	for i := 0; i < len(s); i++ {
		c := s[i]
		if !(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || c == '-' || c == '_') {
			return false
		}
	}
	return true
}

// isPKCEVerifier reports RFC 7636 code-verifier syntax: 43 to 128 unreserved characters.
func isPKCEVerifier(s string) bool {
	if len(s) < 43 || len(s) > 128 {
		return false
	}
	for i := 0; i < len(s); i++ {
		c := s[i]
		if !(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || c == '-' || c == '.' || c == '_' || c == '~') {
			return false
		}
	}
	return true
}

func decodeSingleJSON(body []byte, dst any) error {
	dec := json.NewDecoder(bytes.NewReader(body))
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		return err
	}
	var extra any
	if err := dec.Decode(&extra); !errors.Is(err, io.EOF) {
		if err == nil {
			return errors.New("multiple JSON values")
		}
		return err
	}
	return nil
}
