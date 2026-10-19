package ticket

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestIssueSignsTheClaims(t *testing.T) {
	seed := make([]byte, ed25519.SeedSize)
	key := ed25519.NewKeyFromSeed(seed)
	s := NewSigner("2026-10", key, 5*time.Minute)
	now := time.Unix(1_792_404_000, 0)

	raw, claims := s.Issue(Request{AccountID: "acc", Target: Target{Kind: "capture", ID: "sess"},
		Poses: []string{"side"}, MaxFiles: 1, MaxBytes: 10 << 20}, now)

	parts := strings.Split(raw, ".")
	if len(parts) != 3 || parts[0] != "v1" {
		t.Fatalf("format: %q", raw)
	}
	sig, _ := base64.RawURLEncoding.DecodeString(parts[2])
	if !ed25519.Verify(key.Public().(ed25519.PublicKey), []byte(parts[0]+"."+parts[1]), sig) {
		t.Fatal("signature does not verify")
	}
	payload, _ := base64.RawURLEncoding.DecodeString(parts[1])
	var got Claims
	if err := json.Unmarshal(payload, &got); err != nil {
		t.Fatal(err)
	}
	if got.JTI != claims.JTI || got.Poses[0] != "side" || got.EXP-got.IAT != 300 || got.KID != "2026-10" {
		t.Fatalf("claims: %+v", got)
	}
}

func TestPublicKeyForm(t *testing.T) {
	s := NewSigner("k1", ed25519.NewKeyFromSeed(make([]byte, 32)), time.Minute)
	kid, enc, ok := strings.Cut(s.PublicKey(), ":")
	raw, err := base64.RawURLEncoding.DecodeString(enc)
	if !ok || kid != "k1" || err != nil || len(raw) != ed25519.PublicKeySize {
		t.Fatalf("public key %q", s.PublicKey())
	}
}
