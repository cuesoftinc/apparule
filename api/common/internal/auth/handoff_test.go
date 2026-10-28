package auth

import (
	"bytes"
	"testing"
)

func TestSessionTokenSealing(t *testing.T) {
	aad := HandoffAAD(HandoffChannelBody, HashHandoffCode("code"))
	sealed, err := SealSessionToken("secret", "jwt", aad)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(sealed, []byte("jwt")) {
		t.Fatal("token stored in the clear")
	}
	got, err := OpenSessionToken("secret", sealed, aad)
	if err != nil || got != "jwt" {
		t.Fatalf("open = %q, %v", got, err)
	}
	if _, err := OpenSessionToken("other", sealed, aad); err == nil {
		t.Fatal("wrong secret opened the token")
	}
	other := HandoffAAD(HandoffChannelCookie, HashHandoffCode("code"))
	if _, err := OpenSessionToken("secret", sealed, other); err == nil {
		t.Fatal("token opened under another channel")
	}
}

func TestVerifierMatchesChallenge(t *testing.T) {
	verifier := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ"
	if !VerifierMatchesChallenge(verifier, PKCEChallengeS256(verifier)) {
		t.Fatal("matching pair rejected")
	}
	if VerifierMatchesChallenge(verifier+"x", PKCEChallengeS256(verifier)) {
		t.Fatal("wrong verifier accepted")
	}
}
