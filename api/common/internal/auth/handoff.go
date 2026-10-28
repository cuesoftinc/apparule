package auth

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
)

const (
	HandoffChannelBody   = "body"
	HandoffChannelCookie = "cookie"
)

// ErrHandoffInvalid covers every unredeemable handoff: unknown, expired,
// already used on another channel, wrong verifier or a disabled account.
var ErrHandoffInvalid = errors.New("sso handoff invalid")

// HashHandoffCode is how a one-time code is stored: never in the clear.
func HashHandoffCode(code string) string {
	sum := sha256.Sum256([]byte(code))
	return hex.EncodeToString(sum[:])
}

// VerifierMatchesChallenge checks a PKCE verifier against the stored challenge.
func VerifierMatchesChallenge(verifier, challenge string) bool {
	if verifier == "" || challenge == "" {
		return false
	}
	return hmac.Equal([]byte(PKCEChallengeS256(verifier)), []byte(challenge))
}

// HandoffAAD binds a sealed token to the channel and code it was issued for.
func HandoffAAD(channel, codeHash string) []byte {
	return []byte(channel + ":" + codeHash)
}

// SealSessionToken encrypts the session token kept for the replay window.
func SealSessionToken(secret, token string, aad []byte) ([]byte, error) {
	aead, err := sessionTokenAEAD(secret)
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}
	return aead.Seal(nonce, nonce, []byte(token), aad), nil
}

func OpenSessionToken(secret string, ciphertext, aad []byte) (string, error) {
	aead, err := sessionTokenAEAD(secret)
	if err != nil {
		return "", err
	}
	if len(ciphertext) < aead.NonceSize() {
		return "", errors.New("session token ciphertext is truncated")
	}
	plaintext, err := aead.Open(nil, ciphertext[:aead.NonceSize()], ciphertext[aead.NonceSize():], aad)
	if err != nil {
		return "", err
	}
	return string(plaintext), nil
}

func sessionTokenAEAD(secret string) (cipher.AEAD, error) {
	if secret == "" {
		return nil, errors.New("SESSION_SECRET is required for durable SSO handoffs")
	}
	key := sha256.Sum256([]byte(secret))
	block, err := aes.NewCipher(key[:])
	if err != nil {
		return nil, err
	}
	return cipher.NewGCM(block)
}
