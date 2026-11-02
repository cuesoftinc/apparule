package auth

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestTokenRoundTrip(t *testing.T) {
	id := uuid.NewString()
	now := time.Now()
	raw, err := IssueToken("secret", time.Hour, id, "a@example.com", 3, now)
	if err != nil {
		t.Fatal(err)
	}
	c, err := ParseToken("secret", raw)
	if err != nil {
		t.Fatal(err)
	}
	if c.Subject != id || c.Email != "a@example.com" || c.SessionEpoch != 3 {
		t.Fatalf("claims = %+v", c)
	}
}

func TestTokenRejects(t *testing.T) {
	id := uuid.NewString()
	now := time.Now()
	good, _ := IssueToken("secret", time.Hour, id, "a@example.com", 0, now)
	expired, _ := IssueToken("secret", time.Hour, id, "a@example.com", 0, now.Add(-3*time.Hour))
	badSub, _ := IssueToken("secret", time.Hour, "not-a-uuid", "a@example.com", 0, now)
	tests := []struct {
		name   string
		secret string
		raw    string
		want   error
	}{
		{"wrong secret", "other", good, ErrInvalidToken},
		{"expired", "secret", expired, ErrExpired},
		{"subject not a uuid", "secret", badSub, ErrInvalidToken},
		{"garbage", "secret", "x.y.z", ErrInvalidToken},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if _, err := ParseToken(tt.secret, tt.raw); !errors.Is(err, tt.want) {
				t.Fatalf("err = %v, want %v", err, tt.want)
			}
		})
	}
	if _, err := IssueToken("", time.Hour, id, "a@example.com", 0, now); err == nil {
		t.Fatal("empty secret must not sign")
	}
}
