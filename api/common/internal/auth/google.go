// Package auth is Google SSO and the API's own session: the Google
// authorization-code client with PKCE, the sealed one-time handoff and the
// signed session token.
package auth

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	googleAuthorizeURL = "https://accounts.google.com/o/oauth2/v2/auth"
	googleTokenURL     = "https://oauth2.googleapis.com/token"
	googleUserInfoURL  = "https://www.googleapis.com/oauth2/v3/userinfo"
)

// ssoHTTPClient bounds outbound Google calls under the server's write timeout.
var ssoHTTPClient = &http.Client{Timeout: 15 * time.Second}

// bodySnippet caps upstream response bodies quoted in errors.
func bodySnippet(b []byte) string {
	const max = 512
	if len(b) > max {
		return string(b[:max]) + "..."
	}
	return string(b)
}

// Identity is what the rest of the service learns from Google.
type Identity struct {
	Sub     string
	Email   string
	Name    string
	Picture string
}

type GoogleSSO struct {
	clientID     string
	clientSecret string
}

func NewGoogleSSO(clientID, clientSecret string) *GoogleSSO {
	return &GoogleSSO{clientID: clientID, clientSecret: clientSecret}
}

// PKCEChallengeS256 derives the S256 code challenge for a PKCE code verifier.
func PKCEChallengeS256(verifier string) string {
	sum := sha256.Sum256([]byte(verifier))
	return base64.RawURLEncoding.EncodeToString(sum[:])
}

func (g *GoogleSSO) AuthorizeURL(redirectURI, state, codeChallenge string) string {
	q := url.Values{
		"client_id":             {g.clientID},
		"response_type":         {"code"},
		"redirect_uri":          {redirectURI},
		"scope":                 {"openid email profile"},
		"state":                 {state},
		"code_challenge":        {codeChallenge},
		"code_challenge_method": {"S256"},
		"access_type":           {"offline"},
	}
	return googleAuthorizeURL + "?" + q.Encode()
}

type googleProfile struct {
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
}

// ExchangeCode redeems the authorization code and reads the Google profile.
func (g *GoogleSSO) ExchangeCode(ctx context.Context, code, redirectURI, codeVerifier string) (*Identity, error) {
	form := url.Values{
		"client_id":     {g.clientID},
		"client_secret": {g.clientSecret},
		"code":          {code},
		"redirect_uri":  {redirectURI},
		"grant_type":    {"authorization_code"},
		"code_verifier": {codeVerifier},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, googleTokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return nil, fmt.Errorf("google sso: build token request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := ssoHTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("google sso: token exchange: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("google sso: read token response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google sso: token exchange returned %d: %s", resp.StatusCode, bodySnippet(body))
	}

	var tokenResp struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return nil, fmt.Errorf("google sso: decode token response: %w", err)
	}

	profile, err := g.fetchProfile(ctx, tokenResp.AccessToken)
	if err != nil {
		return nil, err
	}
	if profile.Sub == "" || profile.Email == "" || !profile.EmailVerified {
		return nil, fmt.Errorf("google sso: profile has no verified email")
	}
	return &Identity{Sub: profile.Sub, Email: profile.Email, Name: profile.Name, Picture: profile.Picture}, nil
}

func (g *GoogleSSO) fetchProfile(ctx context.Context, accessToken string) (*googleProfile, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, googleUserInfoURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := ssoHTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("google sso: fetch profile: %w", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google sso: profile fetch returned %d: %s", resp.StatusCode, bodySnippet(raw))
	}

	var profile googleProfile
	if err := json.Unmarshal(raw, &profile); err != nil {
		return nil, fmt.Errorf("google sso: decode profile: %w", err)
	}
	return &profile, nil
}
