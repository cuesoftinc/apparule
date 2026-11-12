package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

var paystackHTTP = &http.Client{Timeout: 8 * time.Second}
var paystackBaseURL = "https://api.paystack.co"

type verifiedTransaction struct {
	ID        json.Number `json:"id"`
	Status    string      `json:"status"`
	Reference string      `json:"reference"`
	Amount    json.Number `json:"amount"`
	Currency  string      `json:"currency"`
	Domain    string      `json:"domain"`
}

type verifyResponse struct {
	Status bool                `json:"status"`
	Data   verifiedTransaction `json:"data"`
}

// verifyReference calls Paystack only from the server and preserves the
// reference as one escaped path segment. It returns only a fully decoded API response.
func (s *Services) verifyReference(ctx context.Context, reference string) (verifiedTransaction, error) {
	if s.Config.Paystack.SecretKey == "" {
		return verifiedTransaction{}, errors.New("Paystack is not configured")
	}
	client := s.PaystackHTTPClient
	if client == nil {
		client = paystackHTTP
	}
	baseURL := s.PaystackBaseURL
	if baseURL == "" {
		baseURL = paystackBaseURL
	}
	return requestPaystackVerification(ctx, client, baseURL, s.Config.Paystack.SecretKey, reference)
}

func requestPaystackVerification(ctx context.Context, client *http.Client, baseURL, secret, reference string) (verifiedTransaction, error) {
	u := strings.TrimRight(baseURL, "/") + "/transaction/verify/" + url.PathEscape(reference)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return verifiedTransaction{}, err
	}
	req.Header.Set("Authorization", "Bearer "+secret)
	req.Header.Set("Accept", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return verifiedTransaction{}, fmt.Errorf("Paystack verification request failed: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return verifiedTransaction{}, fmt.Errorf("Paystack verification returned HTTP %d", resp.StatusCode)
	}
	var body verifyResponse
	d := json.NewDecoder(io.LimitReader(resp.Body, 1<<20))
	d.UseNumber()
	if err := d.Decode(&body); err != nil {
		return verifiedTransaction{}, fmt.Errorf("invalid Paystack verification response: %w", err)
	}
	var trailing any
	if err := d.Decode(&trailing); err != io.EOF {
		return verifiedTransaction{}, errors.New("unexpected trailing Paystack verification data")
	}
	if !body.Status {
		return verifiedTransaction{}, errors.New("Paystack verification API reported failure")
	}
	if body.Data.ID == "" || body.Data.Reference == "" || body.Data.Status == "" || body.Data.Amount == "" || body.Data.Currency == "" || body.Data.Domain == "" {
		return verifiedTransaction{}, errors.New("incomplete Paystack transaction response")
	}
	transactionID, err := body.Data.ID.Int64()
	if err != nil || transactionID <= 0 {
		return verifiedTransaction{}, errors.New("invalid Paystack transaction ID")
	}
	amount, err := body.Data.Amount.Int64()
	if err != nil || amount <= 0 {
		return verifiedTransaction{}, errors.New("invalid Paystack transaction amount")
	}
	return body.Data, nil
}

// VerifyPayment verifies a customer return reference and hands a successful
// charge to the same provider-event decision path as a webhook.
func (s *Services) VerifyPayment(ctx context.Context, p *Principal, requestID, reference string) (string, error) {
	if len(reference) < 5 || len(reference) > 100 || !strings.HasPrefix(reference, "apr_") {
		return "", invalid("Invalid payment reference")
	}
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		o, err := repository.OrderByReference(ctx, tx, reference)
		if err != nil {
			return err
		}
		if o.CustomerAccountID != p.AccountID {
			return repository.ErrNotFound
		}
		if o.ID != requestID || o.Status != "quoted" || o.Payment == nil || o.Payment.State != "pending" || o.Reference == nil || *o.Reference != reference {
			return conflict("payment_not_pending", "This payment is not pending")
		}
		claimed, err := repository.ClaimPaymentVerification(ctx, tx, reference)
		if err != nil {
			return err
		}
		if !claimed {
			return rateLimited(time.Minute, "Payment verification is already in progress")
		}
		return nil
	})
	if err != nil {
		return "", err
	}
	data, err := s.verifyReference(ctx, reference)
	if err != nil {
		slog.WarnContext(ctx, "Paystack transaction verification failed", "reference", reference, "error", err)
		return "", newErr(http.StatusBadGateway, "payment_verification_unavailable", "Payment status could not be confirmed")
	}
	if data.Reference != reference {
		slog.ErrorContext(ctx, "Paystack verification reference mismatch", "reference", reference)
		return "", conflict("payment_reference_mismatch", "Payment reference did not match")
	}
	if data.Status != "success" {
		return "pending", nil
	}
	if err := s.enqueueVerified(ctx, data); err != nil {
		return "", err
	}
	return "verification_started", nil
}

// VerifyPendingPayment is used by the bounded scheduler sweep. Invalid and
// transient responses leave the order untouched for a later retry.
func (s *Services) VerifyPendingPayment(ctx context.Context, reference string) error {
	if s.Config.Paystack.SecretKey == "" {
		return nil
	}
	claimed := false
	if err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		var err error
		claimed, err = repository.ClaimPaymentVerification(ctx, tx, reference)
		return err
	}); err != nil {
		return err
	}
	if !claimed {
		return nil
	}
	data, err := s.verifyReference(ctx, reference)
	if err != nil {
		return err
	}
	if data.Reference != reference || data.Status != "success" {
		return nil
	}
	return s.enqueueVerified(ctx, data)
}

func (s *Services) enqueueVerified(ctx context.Context, data verifiedTransaction) error {
	if data.Domain != "" && data.Domain != "test" && data.Domain != "live" {
		return errors.New("unexpected Paystack transaction domain")
	}
	if strings.HasPrefix(s.Config.Paystack.SecretKey, "sk_test_") && data.Domain == "live" || strings.HasPrefix(s.Config.Paystack.SecretKey, "sk_live_") && data.Domain == "test" {
		return errors.New("Paystack transaction environment does not match configured key")
	}
	raw, err := json.Marshal(data)
	if err != nil {
		return err
	}
	sum := sha256.Sum256(append([]byte("verified:"), raw...))
	key := hex.EncodeToString(sum[:])
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		id, received, stored, err := repository.InsertProviderEvent(ctx, tx, "paystack", key, "charge.success", raw)
		if err != nil || !stored {
			return err
		}
		order, err := repository.OrderByReference(ctx, tx, data.Reference)
		if err != nil {
			return err
		}
		amount, currency, err := repository.PaymentAttemptAmount(ctx, tx, data.Reference)
		if err != nil {
			return err
		}
		return repository.EnqueueRequest(ctx, tx, kafka.EventPaymentsProviderEvent, id, id, map[string]any{
			"provider_event_id": id, "provider": "paystack", "event": "charge.success",
			"received_at": received.UTC().Format(time.RFC3339Nano), "payload": json.RawMessage(raw),
			"order": map[string]any{"request_id": order.ID, "status": order.Status, "reference": data.Reference,
				"quote":   map[string]any{"amount": derefInt64(order.QuoteCents), "currency": order.Currency},
				"payment": map[string]any{"amount": amount, "currency": currency}},
		})
	})
}

func derefInt64(v *int64) int64 {
	if v == nil {
		return 0
	}
	return *v
}
