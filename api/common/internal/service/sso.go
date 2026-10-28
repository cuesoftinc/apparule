package service

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const (
	// ssoHandoffTTL is how long the browser has to redeem a handoff.
	ssoHandoffTTL = 5 * time.Minute
	// ssoHandoffReplayTTL is how long a redeemed code returns the same session.
	ssoHandoffReplayTTL = time.Minute
)

func randomURLToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// CreateSSOHandoff signs the account in after Google and returns the two
// one-time codes: the URL-visible body code (redeemed with the PKCE verifier)
// and the cookie code (redeemed from an HttpOnly cookie).
func (s *Services) CreateSSOHandoff(ctx context.Context, accountID, challenge string) (bodyCode, cookieCode string, err error) {
	if bodyCode, err = randomURLToken(); err != nil {
		return "", "", err
	}
	if cookieCode, err = randomURLToken(); err != nil {
		return "", "", err
	}
	now := s.Now()
	err = s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		return repository.CreateSSOHandoff(ctx, tx, repository.NewSSOHandoff{
			BodyCodeHash:   auth.HashHandoffCode(bodyCode),
			CookieCodeHash: auth.HashHandoffCode(cookieCode),
			AccountID:      accountID,
			Challenge:      challenge,
			ExpiresAt:      now.Add(ssoHandoffTTL),
		}, now)
	})
	return bodyCode, cookieCode, err
}

// RedeemSSOHandoff turns a handoff code into the session token. The first
// redemption issues and seals the token; a repeat on the same channel within
// the replay window returns the same one, anything else is invalid.
func (s *Services) RedeemSSOHandoff(ctx context.Context, code, channel, verifier string) (string, error) {
	codeHash := auth.HashHandoffCode(code)
	var token string
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		now := s.Now()
		h, err := repository.LockSSOHandoff(ctx, tx, codeHash, channel, now)
		if err != nil {
			return err
		}
		if channel == auth.HandoffChannelBody && !auth.VerifierMatchesChallenge(verifier, h.Challenge) {
			return auth.ErrHandoffInvalid
		}
		if h.Channel != nil && *h.Channel != channel {
			return auth.ErrHandoffInvalid
		}
		state, err := repository.GetSessionState(ctx, tx, h.AccountID)
		if err != nil {
			return err
		}
		if state.Suspended {
			return auth.ErrHandoffInvalid
		}
		aad := auth.HandoffAAD(channel, codeHash)
		if len(h.TokenCiphertext) > 0 {
			if state.Epoch != h.SessionEpoch {
				return auth.ErrHandoffInvalid
			}
			token, err = auth.OpenSessionToken(s.Config.Auth.SessionSecret, h.TokenCiphertext, aad)
			return err
		}
		if h.Channel != nil || h.ConsumedAt != nil {
			return auth.ErrHandoffInvalid
		}
		p, err := repository.LoadPrincipal(ctx, tx, h.AccountID)
		if err != nil {
			return err
		}
		token, err = auth.IssueToken(s.Config.Auth.JWTSecret, s.Config.Auth.JWTAccessTTL, h.AccountID, p.Email, state.Epoch, now)
		if err != nil {
			return err
		}
		sealed, err := auth.SealSessionToken(s.Config.Auth.SessionSecret, token, aad)
		if err != nil {
			return err
		}
		return repository.MarkSSOHandoffRedeemed(ctx, tx, h.ID, channel, sealed, state.Epoch, now, now.Add(ssoHandoffReplayTTL))
	})
	if errors.Is(err, repository.ErrNotFound) {
		return "", auth.ErrHandoffInvalid
	}
	if err != nil {
		return "", err
	}
	return token, nil
}

// ResolveSession checks a verified token against the account: the epoch must
// match, so a revoke ends every older token. It returns auth.ErrSessionInvalid
// for a stale token and the principal otherwise.
func (s *Services) ResolveSession(ctx context.Context, claims *auth.Claims) (*Principal, error) {
	var p *Principal
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		state, err := repository.GetSessionState(ctx, tx, claims.Subject)
		if err != nil {
			return err
		}
		if state.Epoch != claims.SessionEpoch {
			return auth.ErrSessionInvalid
		}
		p, err = repository.LoadPrincipal(ctx, tx, claims.Subject)
		return err
	})
	if errors.Is(err, repository.ErrNotFound) {
		return nil, auth.ErrSessionInvalid
	}
	return p, err
}

// RevokeSession ends every session of the account (logout).
func (s *Services) RevokeSession(ctx context.Context, accountID string) error {
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		return repository.BumpSessionEpoch(ctx, tx, accountID)
	})
}
