// Package wake settles a scaled-to-zero service so its Kafka consumers run
// (shared-messaging.md, "Scale to zero"). Cloud Run gives an instance CPU
// only while it serves a request (S-14), so a bare GET /health starts it but
// its consumers stall once that answer is sent. Settle is the wake that
// waits: POST /internal/settle, which the target answers only after it has
// handled what is waiting for it.
//
// Settling is best-effort: a missed settle leaves the message in Kafka, and
// the every-minute captures job settles the services again.
package wake

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"golang.org/x/sync/errgroup"
)

// settleTimeout covers a cold start, a consumer-group join and the target's
// own settle budget (20 s).
const settleTimeout = 25 * time.Second

const metadataIdentity = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity"

type Waker struct {
	client *http.Client
	// idTokens: on Cloud Run, sign each call with the service account's ID
	// token, because the processing services only accept authenticated calls.
	idTokens bool
	identity string
}

// New returns a Waker. On Cloud Run (a service sets K_SERVICE, a job
// CLOUD_RUN_JOB) calls carry an ID token for the target; elsewhere they go
// out unauthenticated.
func New() *Waker {
	return &Waker{
		client:   &http.Client{},
		idTokens: os.Getenv("K_SERVICE") != "" || os.Getenv("CLOUD_RUN_JOB") != "",
		identity: metadataIdentity,
	}
}

// Settle asks base to handle everything waiting for it and waits for the
// answer, up to settleTimeout. An empty base (compose, Helm: the services
// always run) does nothing.
func (w *Waker) Settle(ctx context.Context, base, reason string) error {
	if base == "" {
		return nil
	}
	base = strings.TrimRight(base, "/")
	ctx, cancel := context.WithTimeout(ctx, settleTimeout)
	defer cancel()
	caughtUp, err := w.call(ctx, base)
	if err != nil {
		slog.WarnContext(ctx, "settle failed", "step", "settle", "target", host(base), "reason", reason, "error", err)
		return err
	}
	slog.InfoContext(ctx, "settled service", "step", "settle", "target", host(base), "reason", reason, "caught_up", caughtUp)
	return nil
}

// SettleAll settles every distinct non-empty base at once and returns when
// all have answered.
func (w *Waker) SettleAll(ctx context.Context, reason string, bases ...string) {
	var g errgroup.Group
	seen := map[string]bool{}
	for _, base := range bases {
		if base == "" || seen[base] {
			continue
		}
		seen[base] = true
		g.Go(func() error { return w.Settle(ctx, base, reason) })
	}
	_ = g.Wait()
}

func (w *Waker) call(ctx context.Context, base string) (bool, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/internal/settle", nil)
	if err != nil {
		return false, err
	}
	if w.idTokens {
		token, err := w.idToken(ctx, base)
		if err != nil {
			return false, fmt.Errorf("id token: %w", err)
		}
		req.Header.Set("Authorization", "Bearer "+token)
	}
	res, err := w.client.Do(req)
	if err != nil {
		return false, err
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(res.Body, 64<<10))
	if res.StatusCode >= 300 {
		return false, fmt.Errorf("status %d", res.StatusCode)
	}
	var answer struct {
		CaughtUp bool `json:"caught_up"`
	}
	_ = json.Unmarshal(body, &answer)
	return answer.CaughtUp, nil
}

// idToken asks the metadata server for an ID token whose audience is the
// target service's URL, which is what Cloud Run checks.
func (w *Waker) idToken(ctx context.Context, audience string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		w.identity+"?audience="+url.QueryEscape(audience), nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Metadata-Flavor", "Google")
	res, err := w.client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	body, err := io.ReadAll(io.LimitReader(res.Body, 64<<10))
	if err != nil {
		return "", err
	}
	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("metadata status %d", res.StatusCode)
	}
	return strings.TrimSpace(string(body)), nil
}

// host keeps logs readable: the service host, never a query string.
func host(base string) string {
	if u, err := url.Parse(base); err == nil && u.Host != "" {
		return u.Host
	}
	return base
}
