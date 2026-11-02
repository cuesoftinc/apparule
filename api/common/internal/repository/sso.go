package repository

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// SSOHandoff is a one-time code pair awaiting redemption. Codes are stored
// only as hashes; TokenCiphertext is the sealed session token kept for the
// replay window.
type SSOHandoff struct {
	ID              string
	AccountID       string
	Challenge       string
	Channel         *string
	TokenCiphertext []byte
	SessionEpoch    int64
	ExpiresAt       time.Time
	ConsumedAt      *time.Time
}

type NewSSOHandoff struct {
	BodyCodeHash   string
	CookieCodeHash string
	AccountID      string
	Challenge      string
	ExpiresAt      time.Time
}

// CreateSSOHandoff stores a handoff, pruning expired ones first.
func CreateSSOHandoff(ctx context.Context, tx pgx.Tx, h NewSSOHandoff, now time.Time) error {
	if _, err := tx.Exec(ctx, `DELETE FROM sso_handoff WHERE id IN (
			SELECT id FROM sso_handoff WHERE expires_at < $1 LIMIT 100)`, now); err != nil {
		return err
	}
	_, err := tx.Exec(ctx, `INSERT INTO sso_handoff (body_code_hash, cookie_code_hash, account_id, challenge, expires_at)
		VALUES ($1, $2, $3, $4, $5)`, h.BodyCodeHash, h.CookieCodeHash, h.AccountID, h.Challenge, h.ExpiresAt)
	return translate(err)
}

// LockSSOHandoff reads the handoff for a code hash on its channel and holds
// the row until the transaction ends, so a code redeems once.
func LockSSOHandoff(ctx context.Context, tx pgx.Tx, codeHash, channel string, now time.Time) (*SSOHandoff, error) {
	column := "body_code_hash"
	if channel == "cookie" {
		column = "cookie_code_hash"
	}
	var h SSOHandoff
	err := tx.QueryRow(ctx, `SELECT id, account_id, challenge, channel, token_ciphertext, session_epoch, expires_at, consumed_at
		FROM sso_handoff WHERE `+column+` = $1 AND expires_at > $2 FOR UPDATE`, codeHash, now).
		Scan(&h.ID, &h.AccountID, &h.Challenge, &h.Channel, &h.TokenCiphertext, &h.SessionEpoch, &h.ExpiresAt, &h.ConsumedAt)
	if err != nil {
		return nil, translate(err)
	}
	return &h, nil
}

// MarkSSOHandoffRedeemed records the first redemption and shrinks the expiry
// to the replay window.
func MarkSSOHandoffRedeemed(ctx context.Context, tx pgx.Tx, id, channel string, ciphertext []byte, epoch int64, now, expiresAt time.Time) error {
	_, err := tx.Exec(ctx, `UPDATE sso_handoff SET channel = $2, token_ciphertext = $3, session_epoch = $4,
		consumed_at = $5, expires_at = $6 WHERE id = $1`, id, channel, ciphertext, epoch, now, expiresAt)
	return translate(err)
}
