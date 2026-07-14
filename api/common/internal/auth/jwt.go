package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"time"
)

type jwtPayload struct {
	Email string `json:"email"`
	Exp   int64  `json:"exp"`
}

// GenerateJWT creates an HMAC-SHA256 session token that expires in 24 hours.
//
// NOTE(security-prd): this is the migrated hand-rolled implementation. Replace
// with a vetted library (golang-jwt/v5) and add verification during the
// security pass.
func (s *Service) GenerateJWT(email string) (string, error) {
	header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"HS256","typ":"JWT"}`))

	payloadBytes, err := json.Marshal(jwtPayload{
		Email: email,
		Exp:   time.Now().Add(24 * time.Hour).Unix(),
	})
	if err != nil {
		return "", err
	}
	payload := base64.RawURLEncoding.EncodeToString(payloadBytes)

	unsigned := header + "." + payload
	h := hmac.New(sha256.New, s.jwtSecret)
	h.Write([]byte(unsigned))
	signature := base64.RawURLEncoding.EncodeToString(h.Sum(nil))
	return unsigned + "." + signature, nil
}
