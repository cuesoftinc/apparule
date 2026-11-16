package service_test

import (
	"context"
	"crypto/hmac"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/sweep"
)

type verificationRoundTripper func(*http.Request) (*http.Response, error)

func (f verificationRoundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func insertPaymentOrder(t *testing.T, e *env, customer, designer *service.Principal, reference, state, orderStatus string) string {
	t.Helper()
	ctx := context.Background()
	if designer.DesignerID == nil {
		t.Fatal("designer profile is missing")
	}
	var requestID string
	err := e.db.AsSystem(ctx, func(tx pgx.Tx) error {
		var postID string
		if err := tx.QueryRow(ctx, `INSERT INTO post (designer_id, caption, turnaround_days) VALUES ($1, $2, 14) RETURNING id`,
			*designer.DesignerID, "Payment verification test").Scan(&postID); err != nil {
			return err
		}
		id, err := repository.InsertOrder(ctx, tx, repository.NewOrder{
			PostID: postID, PostCaption: "Payment verification test", CustomerAccountID: customer.AccountID,
			DesignerID: *designer.DesignerID, DesignerAccountID: designer.AccountID,
			Delivery: model.Delivery{}, Snapshot: model.SnapshotValues{},
		})
		if err != nil {
			return err
		}
		requestID = id
		if _, err := tx.Exec(ctx, `UPDATE request SET status = $2, quote_cents = 1000, quoted_at = now() WHERE id = $1`, id, orderStatus); err != nil {
			return err
		}
		if _, err := repository.StartPayment(ctx, tx, id, reference, "NGN", 1000); err != nil {
			return err
		}
		if state != "pending" {
			if _, err := tx.Exec(ctx, `UPDATE payment SET state = $2 WHERE request_id = $1`, id, state); err != nil {
				return err
			}
		}
		_, err = tx.Exec(ctx, `UPDATE payment_attempt SET created_at = now() - interval '2 minutes' WHERE request_id = $1`, id)
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	return requestID
}

func TestPaymentVerificationSweepAndConcurrentSettlement(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	designer := e.signIn(t, "uid-payments-designer", "payments-designer@example.com")
	if _, err := e.s.EnableDesigner(ctx, designer, "Payment Test Designer", ""); err != nil {
		t.Fatal(err)
	}
	designer = e.refresh(t, designer)
	customer := e.signIn(t, "uid-payments-customer", "payments-customer@example.com")

	raceReference := "apr_concurrent_payment_1"
	raceOrder := insertPaymentOrder(t, e, customer, designer, raceReference, "pending", "quoted")
	verificationStarted := make(chan struct{}, 1)
	releaseVerification := make(chan struct{})
	var mu sync.Mutex
	failedOnce := map[string]bool{}
	statusByReference := map[string]string{}
	var requests []string
	e.s.PaystackHTTPClient = &http.Client{Transport: verificationRoundTripper(func(r *http.Request) (*http.Response, error) {
		response := func(status int, body string) (*http.Response, error) {
			return &http.Response{StatusCode: status, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(body)), Request: r}, nil
		}
		const prefix = "/transaction/verify/"
		if r.Method != http.MethodGet || !strings.HasPrefix(r.URL.EscapedPath(), prefix) {
			return response(http.StatusBadRequest, "unexpected request")
		}
		reference, err := url.PathUnescape(strings.TrimPrefix(r.URL.EscapedPath(), prefix))
		if err != nil || r.Header.Get("Authorization") != "Bearer "+paystackSecret {
			return response(http.StatusUnauthorized, "invalid request")
		}
		mu.Lock()
		requests = append(requests, reference)
		transactionStatus := statusByReference[reference]
		if transactionStatus == "" {
			transactionStatus = "success"
		}
		if reference == "apr_sweep_06" && !failedOnce[reference] {
			failedOnce[reference] = true
			mu.Unlock()
			return response(http.StatusServiceUnavailable, "temporary provider failure")
		}
		mu.Unlock()
		if reference == raceReference {
			verificationStarted <- struct{}{}
			<-releaseVerification
		}
		responseReference := reference
		if reference == "apr_mismatch_response" {
			responseReference = "apr_other_reference"
		}
		body := fmt.Sprintf(`{"status":true,"data":{"id":%d,"status":%q,"reference":%q,"amount":1000,"currency":"NGN","domain":"test"}}`, transactionIDFor(reference), transactionStatus, responseReference)
		return response(http.StatusOK, body)
	})}
	e.s.PaystackBaseURL = "https://api.paystack.test"
	for i, status := range []string{"failed", "abandoned", "pending", "ongoing", "processing", "reversed", "provider_unknown"} {
		reference := fmt.Sprintf("apr_status_%02d", i)
		requestID := insertPaymentOrder(t, e, customer, designer, reference, "pending", "quoted")
		mu.Lock()
		statusByReference[reference] = status
		mu.Unlock()
		if result, err := e.s.VerifyPayment(ctx, customer, requestID, reference); err != nil || result != "pending" {
			t.Fatalf("transaction status %q should remain pending, got status=%q err=%v", status, result, err)
		}
	}
	mismatchOrder := insertPaymentOrder(t, e, customer, designer, "apr_mismatch_response", "pending", "quoted")
	if _, err := e.s.VerifyPayment(ctx, customer, mismatchOrder, "apr_mismatch_response"); code(err) != "payment_reference_mismatch" {
		t.Fatalf("mismatched Paystack reference should be rejected, got %v", err)
	}

	// The customer return call is in flight while a valid signed webhook is
	// accepted. Both eventual decisions identify the same provider transaction.
	verifyResult := make(chan error, 1)
	go func() {
		_, err := e.s.VerifyPayment(ctx, customer, raceOrder, raceReference)
		verifyResult <- err
	}()
	select {
	case <-verificationStarted:
	case <-time.After(5 * time.Second):
		t.Fatal("verification did not reach the mocked Paystack server")
	}
	webhook := []byte(fmt.Sprintf(`{"event":"charge.success","data":{"id":%d,"reference":%q,"amount":1000,"currency":"NGN","status":"success"}}`, transactionIDFor(raceReference), raceReference))
	mac := hmac.New(sha512.New, []byte(paystackSecret))
	_, _ = mac.Write(webhook)
	if err := e.s.ReceiveWebhook(ctx, webhook, hex.EncodeToString(mac.Sum(nil))); err != nil {
		t.Fatal(err)
	}
	close(releaseVerification)
	if err := <-verifyResult; err != nil {
		t.Fatal(err)
	}
	if _, err := e.s.VerifyPayment(ctx, customer, raceOrder, raceReference); code(err) != "rate_limited" {
		t.Fatalf("repeated verification should be throttled, got %v", err)
	}

	providerEvents := e.outbox(t, kafka.EventPaymentsProviderEvent)
	if len(providerEvents) != 2 {
		t.Fatalf("verification and webhook should each be handed to commerce once, got %d events", len(providerEvents))
	}
	decision := map[string]any{
		"outcome_id": "30f987af-6095-5854-a2a9-3f1d0a34f75d", "kind": "charge_settled", "request_id": raceOrder,
		"reference": raceReference, "provider_ref": fmt.Sprint(transactionIDFor(raceReference)),
		"amount": map[string]any{"amount": 1000, "currency": "NGN"},
		"fee":    map[string]any{"amount": 100, "currency": "NGN"},
		"ledger": []map[string]any{{"account": "escrow", "amount": 1000}, {"account": "customer_funds", "amount": -1000}},
	}
	var wg sync.WaitGroup
	results := make(chan error, len(providerEvents))
	for _, event := range providerEvents {
		message := make(map[string]any, len(decision)+1)
		for key, value := range decision {
			message[key] = value
		}
		message["provider_event_id"] = event["provider_event_id"]
		raw, err := json.Marshal(message)
		if err != nil {
			t.Fatal(err)
		}
		if err := e.contract.Validate(kafka.EventPaymentsOutcome, raw); err != nil {
			t.Fatal(err)
		}
		requestID := uuid.NewString()
		wg.Add(1)
		go func() {
			defer wg.Done()
			results <- e.s.OnPaymentOutcome(kafka.WithRequestID(ctx, requestID), raw)
		}()
	}
	wg.Wait()
	close(results)
	for err := range results {
		if err != nil {
			t.Fatal(err)
		}
	}
	assertSingleSettlement(t, e, raceOrder, raceReference)
	var movements []repository.Movement
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		var err error
		movements, err = repository.Movements(ctx, tx, time.Now().Add(-time.Minute), time.Now().Add(time.Minute))
		return err
	})
	foundMovement := false
	for _, movement := range movements {
		if movement.RequestID == raceOrder && movement.Kind == "charge" {
			foundMovement = true
			if movement.Reference != raceReference || movement.ProviderRef != fmt.Sprint(transactionIDFor(raceReference)) {
				t.Fatalf("reconciliation movement lost one reference: %+v", movement)
			}
		}
	}
	if !foundMovement {
		t.Fatalf("reconciliation movement for request %s was not returned", raceOrder)
	}
	if _, err := e.s.VerifyPayment(ctx, customer, raceOrder, raceReference); code(err) != "payment_not_pending" {
		t.Fatalf("verification after settlement should not replay payment, got %v", err)
	}

	eligible := make([]string, 7)
	for i := range eligible {
		eligible[i] = fmt.Sprintf("apr_sweep_%02d", i)
		insertPaymentOrder(t, e, customer, designer, eligible[i], "pending", "quoted")
	}
	insertPaymentOrder(t, e, customer, designer, "other_product_reference", "pending", "quoted")
	insertPaymentOrder(t, e, customer, designer, "apr_already_settled", "held", "quoted")
	insertPaymentOrder(t, e, customer, designer, "apr_ineligible_order", "pending", "cancelled")
	insertPaymentOrder(t, e, customer, designer, "apr_recently_checked", "pending", "quoted")
	claimReference := "apr_sweep_00"
	// Hold two distinct database sessions open before they contend for one
	// reference, so this exercises cross-session conditional-update behavior.
	claimConnA, err := e.db.Pool.Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer claimConnA.Release()
	claimConnB, err := e.db.Pool.Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer claimConnB.Release()
	claimTxA, err := claimConnA.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer claimTxA.Rollback(ctx)
	claimTxB, err := claimConnB.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer claimTxB.Rollback(ctx)
	var backendA, backendB int
	if err := claimTxA.QueryRow(ctx, `SELECT pg_backend_pid()`).Scan(&backendA); err != nil {
		t.Fatal(err)
	}
	if err := claimTxB.QueryRow(ctx, `SELECT pg_backend_pid()`).Scan(&backendB); err != nil {
		t.Fatal(err)
	}
	if backendA == backendB {
		t.Fatal("claim transactions unexpectedly share one PostgreSQL session")
	}
	var claims sync.WaitGroup
	claimResults := make(chan bool, 2)
	startClaims := make(chan struct{})
	for _, tx := range []pgx.Tx{claimTxA, claimTxB} {
		claims.Add(1)
		go func(tx pgx.Tx) {
			defer claims.Done()
			<-startClaims
			claimed := false
			_, err := tx.Exec(ctx, `SELECT set_config('app.bypass_rls', 'on', true)`)
			if err == nil {
				claimed, err = repository.ClaimPendingPaymentAttempt(ctx, tx, claimReference)
			}
			if err == nil {
				err = tx.Commit(ctx)
			}
			if err != nil {
				t.Errorf("claim reference: %v", err)
			}
			claimResults <- claimed
		}(tx)
	}
	close(startClaims)
	claims.Wait()
	close(claimResults)
	claimCount := 0
	for claimed := range claimResults {
		if claimed {
			claimCount++
		}
	}
	if claimCount != 1 {
		t.Fatalf("concurrent database claims = %d, want exactly one", claimCount)
	}
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE payment_attempt SET last_verification_at = NULL WHERE reference = ANY($1)`, eligible)
		return err
	})
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE payment_attempt SET last_verification_at = now() WHERE reference = $1`, "apr_recently_checked")
		return err
	})
	var found []string
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		var err error
		found, err = repository.PendingPaymentReferences(ctx, tx, 100)
		return err
	})
	sort.Strings(found)
	sort.Strings(eligible)
	if len(found) != len(eligible) {
		t.Fatalf("eligible references = %v, want only %v", found, eligible)
	}
	for i := range eligible {
		if found[i] != eligible[i] {
			t.Fatalf("eligible references = %v, want only %v", found, eligible)
		}
	}
	// Earlier status and race checks also use the mock transport. Only count
	// provider calls initiated by this sweep onward.
	takeProviderRequests(&mu, &requests)
	var limited []string
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		var err error
		limited, err = repository.PendingPaymentReferences(ctx, tx, 5)
		return err
	})
	if len(limited) != 5 {
		t.Fatalf("limited sweep batch contains %d refs, want 5", len(limited))
	}
	for i, reference := range []string{"apr_sweep_06", "apr_sweep_05", "apr_sweep_04", "apr_sweep_03", "apr_sweep_02"} {
		if limited[i] != reference {
			t.Fatalf("fresh attempt ordering = %v, want oldest unchecked references first", limited)
		}
	}

	lockReleasedAtSettle := false
	job := &sweep.Sweeper{DB: e.db, Services: e.s, Limits: config.Limits{PaymentVerificationBatchSize: 5}, Settle: func(context.Context) {
		conn, err := e.db.Pool.Acquire(ctx)
		if err != nil {
			t.Errorf("acquire connection in settle callback: %v", err)
			return
		}
		defer conn.Release()
		var acquired bool
		if err := conn.QueryRow(ctx, `SELECT pg_try_advisory_lock(4672026)`).Scan(&acquired); err != nil {
			t.Errorf("check sweep lock in settle callback: %v", err)
			return
		}
		lockReleasedAtSettle = acquired
		if acquired {
			_, _ = conn.Exec(ctx, `SELECT pg_advisory_unlock(4672026)`)
		}
	}}
	if err := job.Payments(ctx); err != nil {
		t.Fatal(err)
	}
	if !lockReleasedAtSettle {
		t.Fatal("payment sweep retained its advisory-lock connection while settling")
	}
	if got := len(takeProviderRequests(&mu, &requests)); got != 5 {
		t.Fatalf("first sweep requested %d references, want bounded batch of 5", got)
	}
	if got := len(e.outbox(t, kafka.EventPaymentsProviderEvent)); got != 4 {
		t.Fatalf("first sweep should enqueue four successful references despite one provider failure; got %d", got)
	}

	// The next batch proceeds past the failed first reference and later refs;
	// the failed reference remains pending through the 30-minute backoff.
	job.Settle = nil
	if err := job.Payments(ctx); err != nil {
		t.Fatal(err)
	}
	if got := len(takeProviderRequests(&mu, &requests)); got != 2 {
		t.Fatalf("second sweep should advance to the next two references, got %d requests", got)
	}
	if got := len(e.outbox(t, kafka.EventPaymentsProviderEvent)); got != 2 {
		t.Fatalf("second sweep should enqueue the remaining two successes, got %d", got)
	}
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE payment_attempt SET last_verification_at = now() - interval '31 minutes' WHERE reference = $1`, eligible[6])
		return err
	})
	if err := job.Payments(ctx); err != nil {
		t.Fatal(err)
	}
	if got := len(takeProviderRequests(&mu, &requests)); got != 1 {
		t.Fatalf("retry sweep should retry only the failed reference, got %d", got)
	}
	if got := len(e.outbox(t, kafka.EventPaymentsProviderEvent)); got != 1 {
		t.Fatalf("safe retry should enqueue the previously failed reference, got %d", got)
	}

	// Replaying successful Paystack responses creates no second provider event
	// or settlement input because both the verification claim and provider key
	// are database-backed.
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE payment_attempt SET last_verification_at = now() - interval '31 minutes' WHERE reference = ANY($1)`, eligible)
		return err
	})
	if err := job.Payments(ctx); err != nil {
		t.Fatal(err)
	}
	if got := len(e.outbox(t, kafka.EventPaymentsProviderEvent)); got != 0 {
		t.Fatalf("repeated sweep enqueued %d duplicate provider events", got)
	}

	// A superseded attempt remains visible to verification, but each event
	// carries the current active checkout reference so commerce cannot settle
	// an old payment against the newer attempt.
	oldReference, currentReference := "apr_sweep_20_old", "apr_sweep_21_current"
	supersededOrder := insertPaymentOrder(t, e, customer, designer, oldReference, "pending", "quoted")
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		if _, err := repository.StartPayment(ctx, tx, supersededOrder, currentReference, "NGN", 1000); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `UPDATE payment_attempt SET created_at = now() - interval '2 minutes' WHERE request_id = $1`, supersededOrder)
		return err
	})
	if err := job.Payments(ctx); err != nil {
		t.Fatal(err)
	}
	var supersededEvents []map[string]any
	for _, event := range e.outbox(t, kafka.EventPaymentsProviderEvent) {
		payload := event["payload"].(map[string]any)
		order := event["order"].(map[string]any)
		if payload["reference"] == oldReference {
			supersededEvents = append(supersededEvents, event)
			if order["reference"] != currentReference {
				t.Fatalf("superseded event active reference = %v, want %s", order["reference"], currentReference)
			}
		}
	}
	if len(supersededEvents) != 1 {
		t.Fatalf("sweep should verify retained superseded reference once, got %d matching events", len(supersededEvents))
	}

	staleOutcomeID := uuid.NewString()
	e.deliver(t, kafka.EventPaymentsOutcome, map[string]any{
		"outcome_id": staleOutcomeID, "kind": "charge_settled", "request_id": supersededOrder,
		"reference": oldReference, "provider_ref": fmt.Sprint(transactionIDFor(oldReference)),
		"amount": map[string]any{"amount": 1000, "currency": "NGN"},
		"ledger": []map[string]any{{"account": "escrow", "amount": 1000}, {"account": "customer_funds", "amount": -1000}},
	}, e.s.OnPaymentOutcome)
	var state, activeReference, attention, reason string
	var staleLedgerRows int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		if err := tx.QueryRow(ctx, `SELECT p.state, p.reference, o.attention, o.reason
			FROM payment p JOIN payment_outcome o ON o.request_id = p.request_id WHERE o.outcome_id = $1`, staleOutcomeID).
			Scan(&state, &activeReference, &attention, &reason); err != nil {
			return err
		}
		return tx.QueryRow(ctx, `SELECT count(*) FROM ledger_entry WHERE outcome_id = $1`, staleOutcomeID).Scan(&staleLedgerRows)
	})
	if state != "pending" || activeReference != currentReference || attention != "refund_needed" || reason != "stale_checkout_reference" || staleLedgerRows != 0 {
		t.Fatalf("stale settlement was not safely flagged: payment=%s/%s attention=%s reason=%s ledger_rows=%d",
			state, activeReference, attention, reason, staleLedgerRows)
	}
}

func TestLateDuplicateWebhookIsAcknowledgedWithoutAnotherOutcome(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	designer := e.signIn(t, "uid-late-duplicate-designer", "late-duplicate-designer@example.com")
	if _, err := e.s.EnableDesigner(ctx, designer, "Late Duplicate Designer", ""); err != nil {
		t.Fatal(err)
	}
	designer = e.refresh(t, designer)
	customer := e.signIn(t, "uid-late-duplicate-customer", "late-duplicate-customer@example.com")
	reference := "apr_late_duplicate_1"
	requestID := insertPaymentOrder(t, e, customer, designer, reference, "pending", "quoted")
	transactionID := transactionIDFor(reference)
	e.s.PaystackHTTPClient = &http.Client{Transport: verificationRoundTripper(func(r *http.Request) (*http.Response, error) {
		body := fmt.Sprintf(`{"status":true,"data":{"id":%d,"status":"success","reference":%q,"amount":1000,"currency":"NGN","domain":"test"}}`, transactionID, reference)
		return &http.Response{StatusCode: http.StatusOK, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(body)), Request: r}, nil
	})}
	e.s.PaystackBaseURL = "https://api.paystack.test"
	if status, err := e.s.VerifyPayment(ctx, customer, requestID, reference); err != nil || status != "verification_started" {
		t.Fatalf("verification status=%q err=%v", status, err)
	}
	verifiedEvents := e.outbox(t, kafka.EventPaymentsProviderEvent)
	if len(verifiedEvents) != 1 {
		t.Fatalf("verification queued %d provider events, want 1", len(verifiedEvents))
	}
	verifiedEventID := verifiedEvents[0]["provider_event_id"].(string)
	settled := map[string]any{
		"outcome_id": uuid.NewString(), "kind": "charge_settled", "request_id": requestID,
		"provider_event_id": verifiedEventID, "reference": reference, "provider_ref": fmt.Sprint(transactionID),
		"amount": map[string]any{"amount": 1000, "currency": "NGN"},
		"fee":    map[string]any{"amount": 100, "currency": "NGN"},
		"ledger": []map[string]any{{"account": "escrow", "amount": 1000}, {"account": "customer_funds", "amount": -1000}},
	}
	e.deliverAs(t, kafka.EventPaymentsOutcome, verifiedEventID, settled, e.s.OnPaymentOutcome)

	webhook := []byte(fmt.Sprintf(`{"event":"charge.success","data":{"id":%d,"reference":%q,"amount":1000,"currency":"NGN","status":"success"}}`, transactionID, reference))
	mac := hmac.New(sha512.New, []byte(paystackSecret))
	_, _ = mac.Write(webhook)
	if err := e.s.ReceiveWebhook(ctx, webhook, hex.EncodeToString(mac.Sum(nil))); err != nil {
		t.Fatal(err)
	}
	// The earlier verification event was already drained from the outbox above,
	// so only the newly queued late-webhook event should remain pending now.
	providerEvents := e.outbox(t, kafka.EventPaymentsProviderEvent)
	if len(providerEvents) != 1 {
		t.Fatalf("late webhook produced %d remaining provider events, want 1", len(providerEvents))
	}
	webhookEventID := ""
	for _, event := range providerEvents {
		if event["provider_event_id"] != verifiedEventID {
			webhookEventID = event["provider_event_id"].(string)
		}
	}
	if webhookEventID == "" {
		t.Fatal("late webhook provider event was not queued")
	}
	ack := map[string]any{
		"outcome_id": uuid.NewString(), "kind": "charge_duplicate", "request_id": requestID,
		"provider_event_id": webhookEventID, "reference": reference, "provider_ref": fmt.Sprint(transactionID),
		"amount": map[string]any{"amount": 1000, "currency": "NGN"},
	}
	badAck := make(map[string]any, len(ack))
	for key, value := range ack {
		badAck[key] = value
	}
	badAck["provider_ref"] = "123"
	rawBadAck, err := json.Marshal(badAck)
	if err != nil {
		t.Fatal(err)
	}
	if err := e.contract.Validate(kafka.EventPaymentsOutcome, rawBadAck); err != nil {
		t.Fatal(err)
	}
	if err := e.s.OnPaymentOutcome(kafka.WithRequestID(ctx, webhookEventID), rawBadAck); err == nil {
		t.Fatal("mismatched transaction acknowledgement was accepted")
	}
	e.deliverAs(t, kafka.EventPaymentsOutcome, webhookEventID, ack, e.s.OnPaymentOutcome)
	assertSingleSettlement(t, e, requestID, reference)
	var duplicateOutcomes, processed int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		if err := tx.QueryRow(ctx, `SELECT count(*) FROM payment_outcome WHERE request_id = $1`, requestID).Scan(&duplicateOutcomes); err != nil {
			return err
		}
		return tx.QueryRow(ctx, `SELECT count(*) FROM provider_event WHERE id = ANY($1) AND processed_at IS NOT NULL`, []string{verifiedEventID, webhookEventID}).Scan(&processed)
	})
	if duplicateOutcomes != 1 || processed != 2 {
		t.Fatalf("outcomes=%d processed_provider_events=%d, want one payment outcome and both events processed", duplicateOutcomes, processed)
	}
}

func transactionIDFor(reference string) int64 {
	if reference == "apr_concurrent_payment_1" {
		return 7654321001
	}
	var n int64
	_, _ = fmt.Sscanf(reference, "apr_sweep_%d", &n)
	return 7654322000 + n
}

func takeProviderRequests(mu *sync.Mutex, requests *[]string) []string {
	mu.Lock()
	defer mu.Unlock()
	result := append([]string(nil), (*requests)...)
	*requests = nil
	return result
}

func assertSingleSettlement(t *testing.T, e *env, requestID, reference string) {
	t.Helper()
	var paymentState string
	var outcomes, paidEvents, ledgerRows, payouts, paidTransitions, processedProviderEvents int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		if err := tx.QueryRow(ctx, `SELECT state FROM payment WHERE request_id = $1`, requestID).Scan(&paymentState); err != nil {
			return err
		}
		queries := []struct {
			dst  *int
			sql  string
			args []any
		}{
			{&outcomes, `SELECT count(*) FROM payment_outcome WHERE kind = 'charge_settled' AND request_id = $1`, []any{requestID}},
			{&paidEvents, `SELECT count(*) FROM order_event WHERE request_id = $1 AND kind = 'paid'`, []any{requestID}},
			{&ledgerRows, `SELECT count(*) FROM ledger_entry WHERE request_id = $1`, []any{requestID}},
			{&payouts, `SELECT count(*) FROM payout WHERE request_id = $1`, []any{requestID}},
			{&paidTransitions, `SELECT count(*) FROM outbox WHERE event = $1 AND payload->>'request_id' = $2 AND payload->>'to' = 'paid'`, []any{kafka.EventOrdersTransition, requestID}},
			{&processedProviderEvents, `SELECT count(*) FROM provider_event WHERE payload->>'reference' = $1 AND processed_at IS NOT NULL`, []any{reference}},
		}
		for _, q := range queries {
			if err := tx.QueryRow(ctx, q.sql, q.args...).Scan(q.dst); err != nil {
				return err
			}
		}
		return nil
	})
	var escrow int64
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		var err error
		escrow, err = repository.LedgerBalance(ctx, tx, "escrow")
		return err
	})
	if paymentState != "held" || outcomes != 1 || paidEvents != 1 || ledgerRows != 2 || payouts != 0 || paidTransitions != 1 || processedProviderEvents != 2 {
		t.Fatalf("duplicate settlement effects: payment=%s outcomes=%d paid_events=%d ledger_rows=%d payouts=%d paid_transitions=%d processed_provider_events=%d",
			paymentState, outcomes, paidEvents, ledgerRows, payouts, paidTransitions, processedProviderEvents)
	}
	if escrow != 1000 {
		t.Fatalf("escrow balance = %d, want 1000", escrow)
	}
}
