// Package ticket issues upload tickets (S-15; format in
// api/common/contract/upload-ticket.md). Only api/common holds the signing
// key; api/uploads verifies with the public key.
package ticket

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type Target struct {
	Kind string `json:"kind"` // capture | post_media | attachment
	ID   string `json:"id"`
}

type Claims struct {
	KID       string   `json:"kid"`
	JTI       string   `json:"jti"`
	AccountID string   `json:"account_id"`
	Target    Target   `json:"target"`
	Poses     []string `json:"poses,omitempty"`
	MaxFiles  int      `json:"max_files"`
	MaxBytes  int64    `json:"max_bytes"`
	IAT       int64    `json:"iat"`
	EXP       int64    `json:"exp"`
}

type Signer struct {
	kid string
	key ed25519.PrivateKey
	ttl time.Duration
}

func NewSigner(kid string, key ed25519.PrivateKey, ttl time.Duration) *Signer {
	return &Signer{kid: kid, key: key, ttl: ttl}
}

// Request is what a ticket allows.
type Request struct {
	AccountID string
	Target    Target
	Poses     []string
	MaxFiles  int
	MaxBytes  int64
}

// Issue returns the encoded ticket and its claims.
func (s *Signer) Issue(r Request, now time.Time) (string, Claims) {
	c := Claims{
		KID: s.kid, JTI: uuid.NewString(), AccountID: r.AccountID, Target: r.Target, Poses: r.Poses,
		MaxFiles: r.MaxFiles, MaxBytes: r.MaxBytes, IAT: now.Unix(), EXP: now.Add(s.ttl).Unix(),
	}
	payload, _ := json.Marshal(c) // plain struct; cannot fail
	head := "v1." + base64.RawURLEncoding.EncodeToString(payload)
	return head + "." + base64.RawURLEncoding.EncodeToString(ed25519.Sign(s.key, []byte(head))), c
}

// PublicKey is the verifier's half, in UPLOAD_TICKET_PUBLIC_KEYS form.
func (s *Signer) PublicKey() string {
	return s.kid + ":" + base64.RawURLEncoding.EncodeToString(s.key.Public().(ed25519.PublicKey))
}
