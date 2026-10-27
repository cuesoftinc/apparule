package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// StartPayment creates the pending charge of an order, or points a pending
// one at a new checkout reference, and records the attempt with its amount.
func StartPayment(ctx context.Context, tx pgx.Tx, requestID, reference, currency string, amount int64) (string, error) {
	var ref string
	err := tx.QueryRow(ctx, `INSERT INTO payment (request_id, state, reference, currency, amount_cents) VALUES ($1, 'pending', $2, $3, $4)
		ON CONFLICT (request_id) DO UPDATE SET
			reference = CASE WHEN payment.state = 'pending' THEN EXCLUDED.reference ELSE payment.reference END,
			amount_cents = CASE WHEN payment.state = 'pending' THEN EXCLUDED.amount_cents ELSE payment.amount_cents END,
			updated_at = now()
		RETURNING reference`, requestID, reference, currency, amount).Scan(&ref)
	if err != nil || ref != reference {
		return ref, err
	}
	_, err = tx.Exec(ctx, `INSERT INTO payment_attempt (reference, request_id, amount_cents, currency) VALUES ($1, $2, $3, $4)`,
		reference, requestID, amount, currency)
	return ref, err
}

// CountPaymentAttempts counts an order's checkout references so far.
func CountPaymentAttempts(ctx context.Context, tx pgx.Tx, requestID string) (int, error) {
	var n int
	err := tx.QueryRow(ctx, `SELECT count(*) FROM payment_attempt WHERE request_id = $1`, requestID).Scan(&n)
	return n, err
}

// PaymentAttemptAmount is what the checkout behind a reference was started
// for: a charge settles against it, never the current quote.
func PaymentAttemptAmount(ctx context.Context, tx pgx.Tx, reference string) (int64, string, error) {
	var amount int64
	var currency string
	err := tx.QueryRow(ctx, `SELECT amount_cents, currency FROM payment_attempt WHERE reference = $1`, reference).Scan(&amount, &currency)
	return amount, currency, translate(err)
}

// SettlePayment moves a pending payment to held under the reference that
// settled. It reports false when the payment was not pending, so a second
// charge never books escrow twice.
func SettlePayment(ctx context.Context, tx pgx.Tx, requestID string, reference *string, fee *int64, providerRef *string) (bool, error) {
	tag, err := tx.Exec(ctx, `UPDATE payment SET state = 'held', reference = coalesce($2, reference),
		platform_fee_cents = coalesce($3, platform_fee_cents), provider_ref = coalesce($4, provider_ref), updated_at = now()
		WHERE request_id = $1 AND state = 'pending'`, requestID, reference, fee, providerRef)
	return tag.RowsAffected() > 0, err
}

// SetPaymentState moves a payment, optionally recording the fee and the
// provider's transaction id.
func SetPaymentState(ctx context.Context, tx pgx.Tx, requestID, state string, fee *int64, providerRef *string) error {
	_, err := tx.Exec(ctx, `UPDATE payment SET state = $2, platform_fee_cents = coalesce($3, platform_fee_cents),
		provider_ref = coalesce($4, provider_ref), updated_at = now() WHERE request_id = $1`, requestID, state, fee, providerRef)
	return err
}

func UpsertPayout(ctx context.Context, tx pgx.Tx, requestID, designerID, currency, state string, amount int64, transferRef *string) error {
	_, err := tx.Exec(ctx, `INSERT INTO payout (request_id, designer_id, amount_cents, currency, state, provider_transfer_ref)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (request_id) DO UPDATE SET state = EXCLUDED.state, amount_cents = EXCLUDED.amount_cents,
			provider_transfer_ref = coalesce(EXCLUDED.provider_transfer_ref, payout.provider_transfer_ref), updated_at = now()`,
		requestID, designerID, amount, currency, state, transferRef)
	return err
}

// ── Provider events (S-12) ──────────────────────────────────────────────

// InsertProviderEvent stores a webhook once; a redelivery returns the
// existing row's id and stored = false.
func InsertProviderEvent(ctx context.Context, tx pgx.Tx, provider, key, event string, payload json.RawMessage) (id string, receivedAt time.Time, stored bool, err error) {
	err = tx.QueryRow(ctx, `INSERT INTO provider_event (provider, provider_key, event, payload) VALUES ($1, $2, $3, $4)
		ON CONFLICT (provider, provider_key) DO NOTHING RETURNING id, received_at`, provider, key, event, []byte(payload)).Scan(&id, &receivedAt)
	if err == pgx.ErrNoRows {
		err = tx.QueryRow(ctx, `SELECT id, received_at FROM provider_event WHERE provider = $1 AND provider_key = $2`, provider, key).Scan(&id, &receivedAt)
		return id, receivedAt, false, err
	}
	return id, receivedAt, true, err
}

func MarkProviderEvent(ctx context.Context, tx pgx.Tx, id, outcome string) error {
	_, err := tx.Exec(ctx, `UPDATE provider_event SET processed_at = now(), outcome = $2 WHERE id = $1`, id, outcome)
	return err
}

// ── Outcomes and the ledger (§5.2, §6.3) ────────────────────────────────

type LedgerLine struct {
	Account string `json:"account"`
	Amount  int64  `json:"amount"`
}

// RecordOutcome stores a commerce decision once. It reports false when the
// outcome was already stored (a redelivery).
func RecordOutcome(ctx context.Context, tx pgx.Tx, outcomeID, kind string, requestID, designerID, reason *string, payload json.RawMessage) (bool, error) {
	tag, err := tx.Exec(ctx, `INSERT INTO payment_outcome (outcome_id, kind, request_id, designer_id, reason, payload)
		VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (outcome_id) DO NOTHING`, outcomeID, kind, requestID, designerID, reason, []byte(payload))
	return tag.RowsAffected() > 0, err
}

// FlagOutcome marks a stored outcome for a human (refund_needed).
func FlagOutcome(ctx context.Context, tx pgx.Tx, outcomeID, attention, reason string) error {
	_, err := tx.Exec(ctx, `UPDATE payment_outcome SET attention = $2, reason = coalesce(reason, $3) WHERE outcome_id = $1`,
		outcomeID, attention, reason)
	return err
}

// RecordUnappliedOutcome keeps an outcome common could not apply, flagged
// not_applied; one already stored is left as it is.
func RecordUnappliedOutcome(ctx context.Context, tx pgx.Tx, outcomeID, kind string, requestID, designerID, reason *string, payload json.RawMessage) error {
	_, err := tx.Exec(ctx, `INSERT INTO payment_outcome (outcome_id, kind, request_id, designer_id, reason, payload, attention)
		VALUES ($1, $2, $3, $4, $5, $6, 'not_applied') ON CONFLICT (outcome_id) DO NOTHING`,
		outcomeID, kind, requestID, designerID, reason, []byte(payload))
	return err
}

// AppendLedger appends an outcome's lines; the deferred trigger rejects the
// transaction at commit if they don't sum to zero.
func AppendLedger(ctx context.Context, tx pgx.Tx, outcomeID, requestID, currency string, lines []LedgerLine) error {
	batch := &pgx.Batch{}
	for _, l := range lines {
		batch.Queue(`INSERT INTO ledger_entry (outcome_id, request_id, account, amount, currency) VALUES ($1, $2, $3, $4, $5)`,
			outcomeID, requestID, l.Account, l.Amount, currency)
	}
	return tx.SendBatch(ctx, batch).Close()
}

// LedgerBalance sums an account of the ledger (the money invariant test).
func LedgerBalance(ctx context.Context, tx pgx.Tx, account string) (int64, error) {
	var n int64
	err := tx.QueryRow(ctx, `SELECT coalesce(sum(amount), 0) FROM ledger_entry WHERE account = $1`, account).Scan(&n)
	return n, err
}

// Movement is one provider-facing movement for reconciliation (§6.4).
type Movement struct {
	RequestID string `json:"request_id"`
	Kind      string `json:"kind"`
	Reference string `json:"reference"`
	Amount    struct {
		Amount   int64  `json:"amount"`
		Currency string `json:"currency"`
	} `json:"amount"`
	At time.Time `json:"at"`
}

// Movements lists the charges, payouts and refunds recorded in a window.
func Movements(ctx context.Context, tx pgx.Tx, from, to time.Time) ([]Movement, error) {
	rows, err := tx.Query(ctx, `SELECT o.request_id::text,
			CASE o.kind WHEN 'charge_settled' THEN 'charge' WHEN 'payout_released' THEN 'payout' ELSE 'refund' END,
			coalesce(o.payload->>'provider_ref', o.payload->>'reference', ''),
			(o.payload->'amount'->>'amount')::bigint, o.payload->'amount'->>'currency', o.created_at
		FROM payment_outcome o
		WHERE o.kind IN ('charge_settled', 'payout_released', 'refund_issued') AND o.created_at >= $1 AND o.created_at < $2
		ORDER BY o.created_at`, from, to)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*Movement, error) {
		var m Movement
		err := r.Scan(&m.RequestID, &m.Kind, &m.Reference, &m.Amount.Amount, &m.Amount.Currency, &m.At)
		m.At = m.At.UTC()
		return &m, err
	})
}

// ── Earnings (pages.md B9) ──────────────────────────────────────────────

// Earnings derives a designer's balance, pending escrow and history from
// stored payments and payouts.
func Earnings(ctx context.Context, tx pgx.Tx, designerID string) (*model.Earnings, error) {
	e := &model.Earnings{Currency: "NGN", Transactions: []model.EarningsEntry{}}
	rows, err := tx.Query(ctx, `SELECT r.id, r.order_number, p.state, p.currency, p.amount_cents, p.platform_fee_cents,
			po.provider_transfer_ref, po.state,
			coalesce((SELECT max(created_at) FROM order_event ev WHERE ev.request_id = r.id AND ev.kind = 'paid'), p.created_at),
			coalesce(po.updated_at, p.updated_at)
		FROM payment p JOIN request r ON r.id = p.request_id LEFT JOIN payout po ON po.request_id = r.id
		WHERE r.designer_id = $1 AND p.state IN ('held', 'released')`, designerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id, number, state, currency string
		var amount, fee int64
		var transferRef, payoutState *string
		var paidAt, releasedAt time.Time
		if err := rows.Scan(&id, &number, &state, &currency, &amount, &fee, &transferRef, &payoutState, &paidAt, &releasedAt); err != nil {
			return nil, err
		}
		net := amount - fee
		ref := "#" + number
		if state == "held" {
			e.PendingCents += net
			e.Transactions = append(e.Transactions, model.EarningsEntry{ID: "txn-held-" + id, Kind: "escrow_held", AmountCents: net,
				Currency: currency, OrderNumber: ref, CreatedAt: paidAt})
			continue
		}
		e.BalanceCents += net
		e.Transactions = append(e.Transactions,
			model.EarningsEntry{ID: "txn-payout-" + id, Kind: "payout", AmountCents: net, Currency: currency, OrderNumber: ref,
				ProviderRef: transferRef, CreatedAt: releasedAt},
			model.EarningsEntry{ID: "txn-fee-" + id, Kind: "fee_line", AmountCents: -fee, Currency: currency, OrderNumber: ref,
				CreatedAt: releasedAt})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	sortEntries(e.Transactions)
	return e, nil
}

func sortEntries(list []model.EarningsEntry) {
	for i := 1; i < len(list); i++ {
		for j := i; j > 0 && list[j].CreatedAt.After(list[j-1].CreatedAt); j-- {
			list[j], list[j-1] = list[j-1], list[j]
		}
	}
}
