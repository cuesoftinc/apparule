package service_test

import (
	"context"
	"strings"
	"sync"
	"testing"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
)

// TestReusedSignInHandoffIsInvalid verifies that a one-time handoff code cannot
// be reused to create another account or session. The body and cookie codes are
// distinct, and the handoff is bound to the channel that first redeems it:
// redeeming the cookie code through the cookie channel after the body channel
// was used is rejected with auth.ErrHandoffInvalid, and re-redeeming the body
// code through the body channel within the replay window returns the identical
// session token (no new session is created).
func TestReusedSignInHandoffIsInvalid(t *testing.T) {
	e := setup(t)
	ctx := context.Background()

	// Handoff sealing/issuance requires the auth secrets.
	e.s.Config.Auth.JWTSecret = "test-secret"
	e.s.Config.Auth.SessionSecret = "test-secret"

	// First sign-in creates the account.
	p := e.signIn(t, "uid-reuse", "reuse@example.com")

	verifier := strings.Repeat("v", 43)
	challenge := auth.PKCEChallengeS256(verifier)

	// Capture both codes: they have separate stored hashes (body_code_hash vs
	// cookie_code_hash).
	bodyCode, cookieCode, err := e.s.CreateSSOHandoff(ctx, p.AccountID, challenge)
	if err != nil {
		t.Fatalf("create handoff: %v", err)
	}

	// The first redemption issues the session.
	token1, err := e.s.RedeemSSOHandoff(ctx, bodyCode, auth.HandoffChannelBody, verifier)
	if err != nil || token1 == "" {
		t.Fatalf("first redeem = %q, %v", token1, err)
	}

	// Redeeming the cookie code through the cookie channel is rejected: the
	// handoff is bound to the body channel by the first redemption, so the
	// channel-binding check (h.Channel != channel) returns handoff_invalid.
	if _, err := e.s.RedeemSSOHandoff(ctx, cookieCode, auth.HandoffChannelCookie, verifier); !errorsIsHandoffInvalid(err) {
		t.Fatalf("cookie-channel reuse = %v, want handoff_invalid", err)
	}

	// Re-redeeming the body code through the body channel within the replay
	// window returns the identical session token: no new session is created.
	token2, err := e.s.RedeemSSOHandoff(ctx, bodyCode, auth.HandoffChannelBody, verifier)
	if err != nil || token2 == "" {
		t.Fatalf("second redeem = %q, %v", token2, err)
	}
	if token2 != token1 {
		t.Fatalf("replay returned a different token: %q vs %q", token2, token1)
	}

	// No duplicate account or session: exactly one account row for the subject.
	var count int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT count(*) FROM account WHERE google_sub = $1`, "uid-reuse").Scan(&count)
	})
	if count != 1 {
		t.Fatalf("expected 1 account, got %d", count)
	}
}

func errorsIsHandoffInvalid(err error) bool {
	return err == auth.ErrHandoffInvalid
}

// TestConcurrentFirstSignInsCreateOneAccount verifies that two concurrent
// first sign-ins for the same Google identity converge on a single account,
// with no duplicate rows or inconsistent sessions.
func TestConcurrentFirstSignInsCreateOneAccount(t *testing.T) {
	e := setup(t)
	ctx := context.Background()

	const n = 2
	results := make([]struct {
		id  string
		err error
	}, n)
	start := make(chan struct{})
	var wg sync.WaitGroup

	for i := 0; i < n; i++ {
		i := i
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start // barrier: both requests genuinely overlap
			id, err := e.s.SignInGoogle(ctx, &auth.Identity{
				Sub:     "sub-race",
				Email:   "race@example.com",
				Name:    "Race",
				Picture: "",
			})
			results[i].id = id
			results[i].err = err
		}()
	}
	close(start)
	wg.Wait()

	for i := 0; i < n; i++ {
		if results[i].err != nil {
			t.Fatalf("sign-in %d failed: %v", i, results[i].err)
		}
	}
	if results[0].id != results[1].id {
		t.Fatalf("concurrent sign-ins returned different accounts: %q vs %q", results[0].id, results[1].id)
	}

	// Exactly one account row under the race (google_sub unique constraint).
	var count int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT count(*) FROM account WHERE google_sub = $1`, "sub-race").Scan(&count)
	})
	if count != 1 {
		t.Fatalf("expected 1 account, got %d", count)
	}
}
