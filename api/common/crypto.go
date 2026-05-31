package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"time"
)

// In production, load this from a secure environment variable (.env)
var jwtSecret = []byte("apparule_super_secure_core_secret_key_2026")

type JWTPayload struct {
	Email string `json:"email"`
	Exp   int64  `json:"exp"`
}

// GenerateJWT creates a cryptographically signed HMAC-SHA256 token
func GenerateJWT(email string) (string, error) {
	// 1. Create Header
	header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"HS256","typ":"JWT"}`))

	// 2. Create Payload (Expires in 24 Hours)
	payloadObj := JWTPayload{
		Email: email,
		Exp:   time.Now().Add(24 * time.Hour).Unix(),
	}
	payloadBytes, _ := json.Marshal(payloadObj)
	payload := base64.RawURLEncoding.EncodeToString(payloadBytes)

	// 3. Create Signature
	unsignedToken := header + "." + payload
	h := hmac.New(sha256.New, jwtSecret)
	h.Write([]byte(unsignedToken))
	signature := base64.RawURLEncoding.EncodeToString(h.Sum(nil))

	// Combined production token
	return unsignedToken + "." + signature, nil
}