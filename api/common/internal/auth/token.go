package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrExpired      = errors.New("token expired")
)

// Claims is the API's own session token: the account id is the subject and
// the epoch fences every token issued before a revoke.
type Claims struct {
	jwt.RegisteredClaims
	Email        string `json:"email"`
	SessionEpoch int64  `json:"session_epoch"`
}

// IssueToken signs a session token with the shared HS256 secret.
func IssueToken(secret string, ttl time.Duration, accountID, email string, epoch int64, now time.Time) (string, error) {
	if secret == "" {
		return "", errors.New("JWT_SECRET is required")
	}
	c := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   accountID,
			ID:        uuid.NewString(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
		},
		Email:        email,
		SessionEpoch: epoch,
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString([]byte(secret))
}

// ParseToken verifies signature, algorithm and expiry.
func ParseToken(secret, raw string) (*Claims, error) {
	var c Claims
	_, err := jwt.NewParser(jwt.WithValidMethods([]string{"HS256"}), jwt.WithLeeway(30*time.Second), jwt.WithExpirationRequired()).
		ParseWithClaims(raw, &c, func(*jwt.Token) (any, error) { return []byte(secret), nil })
	switch {
	case errors.Is(err, jwt.ErrTokenExpired):
		return nil, ErrExpired
	case err != nil || uuid.Validate(c.Subject) != nil:
		return nil, ErrInvalidToken
	}
	return &c, nil
}

// ErrSessionInvalid is a well-formed token the account no longer honours.
var ErrSessionInvalid = errors.New("session invalid")
