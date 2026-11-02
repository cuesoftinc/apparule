package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// OrderRow is an order with the ids the service layer needs.
type OrderRow struct {
	model.Order
	CustomerAccountID string
	DesignerAccountID string
	QuotedAt          *time.Time
	ShippedAt         *time.Time
	Reference         *string
	ProviderRef       *string
	RecipientCode     *string
	// PostThumbKey is the frozen post image; the service signs it into Post.ThumbURL.
	PostThumbKey string
}

const orderCols = `r.id, r.order_number, r.post_id, r.post_caption, r.post_thumb_key,
	r.customer_account_id, ca.username, ca.avatar_url,
	r.designer_id, r.designer_account_id, da.username, da.avatar_url,
	r.status, r.notes, r.budget_cents, r.quote_cents, r.currency, r.due_at, to_char(r.target_date, 'YYYY-MM-DD'),
	r.tracking, r.decline_reason, r.dispute_reason, r.dispute_detail, r.delivery, r.snapshot, r.snapshot_id,
	r.quoted_at, r.shipped_at, r.created_at,
	pay.id, pay.provider, pay.state, pay.currency, pay.amount_cents, pay.platform_fee_cents, pay.reference, pay.provider_ref,
	d.recipient_code`

const orderFrom = ` FROM request r
	JOIN account ca ON ca.id = r.customer_account_id
	JOIN account da ON da.id = r.designer_account_id
	JOIN designer_profile d ON d.id = r.designer_id
	LEFT JOIN payment pay ON pay.request_id = r.id`

func scanOrder(r pgx.Row) (*OrderRow, error) {
	var o OrderRow
	var postID *string
	var delivery, snapshot []byte
	var snapshotID string
	var disputeReason *string
	var disputeDetail *string
	var payID, payProvider, payState, payCurrency *string
	var payAmount, payFee *int64
	err := r.Scan(&o.ID, &o.OrderNumber, &postID, &o.Post.Caption, &o.PostThumbKey,
		&o.Customer.ID, &o.Customer.Username, &o.Customer.AvatarURL,
		&o.Designer.ID, &o.DesignerAccountID, &o.Designer.Username, &o.Designer.AvatarURL,
		&o.Status, &o.Notes, &o.BudgetCents, &o.QuoteCents, &o.Currency, &o.DueAt, &o.TargetDate,
		&o.Tracking, &o.DeclineReason, &disputeReason, &disputeDetail, &delivery, &snapshot, &snapshotID,
		&o.QuotedAt, &o.ShippedAt, &o.CreatedAt,
		&payID, &payProvider, &payState, &payCurrency, &payAmount, &payFee, &o.Reference, &o.ProviderRef,
		&o.RecipientCode)
	if err != nil {
		return nil, translate(err)
	}
	o.CustomerAccountID = o.Customer.ID
	if postID != nil {
		o.Post.ID = *postID
	}
	_ = json.Unmarshal(delivery, &o.Delivery)
	o.Snapshot = model.Snapshot{ID: snapshotID, RequestID: o.ID, CreatedAt: o.CreatedAt}
	_ = json.Unmarshal(snapshot, &o.Snapshot.Values)
	if disputeReason != nil {
		o.Dispute = &model.Dispute{Reason: *disputeReason, Detail: disputeDetail}
	}
	if payID != nil {
		o.Payment = &model.Payment{ID: *payID, RequestID: o.ID, Provider: *payProvider, State: *payState,
			Currency: *payCurrency, AmountCents: *payAmount, PlatformFeeCents: *payFee}
	}
	o.Events = []model.OrderEvent{}
	return &o, nil
}

// GetOrder reads one order (party only, by RLS) with its timeline.
func GetOrder(ctx context.Context, tx pgx.Tx, id string) (*OrderRow, error) {
	o, err := scanOrder(tx.QueryRow(ctx, `SELECT `+orderCols+orderFrom+` WHERE r.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return o, loadEvents(ctx, tx, []*OrderRow{o})
}

// LockOrder reads an order FOR UPDATE (of the request row).
func LockOrder(ctx context.Context, tx pgx.Tx, id string) (*OrderRow, error) {
	if _, err := tx.Exec(ctx, `SELECT 1 FROM request WHERE id = $1 FOR UPDATE`, id); err != nil {
		return nil, err
	}
	return GetOrder(ctx, tx, id)
}

// OrderByReference finds the order any of its checkout references belongs to.
func OrderByReference(ctx context.Context, tx pgx.Tx, reference string) (*OrderRow, error) {
	return scanOrder(tx.QueryRow(ctx, `SELECT `+orderCols+orderFrom+`
		WHERE r.id = (SELECT a.request_id FROM payment_attempt a WHERE a.reference = $1)`, reference))
}

func ListOrders(ctx context.Context, tx pgx.Tx, accountID, role string, offset, limit int) ([]*OrderRow, error) {
	col := "r.customer_account_id"
	if role == "designer" {
		col = "r.designer_account_id"
	}
	rows, err := tx.Query(ctx, `SELECT `+orderCols+orderFrom+` WHERE `+col+` = $1 ORDER BY r.created_at DESC, r.id OFFSET $2 LIMIT $3`,
		accountID, offset, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*OrderRow
	for rows.Next() {
		o, err := scanOrder(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, o)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, loadEvents(ctx, tx, out)
}

func loadEvents(ctx context.Context, tx pgx.Tx, orders []*OrderRow) error {
	if len(orders) == 0 {
		return nil
	}
	ids := make([]string, len(orders))
	byID := map[string]*OrderRow{}
	for i, o := range orders {
		ids[i] = o.ID
		byID[o.ID] = o
	}
	rows, err := tx.Query(ctx, `SELECT id, request_id, kind, actor, created_at FROM order_event
		WHERE request_id::text = ANY($1) ORDER BY created_at, id`, ids)
	if err != nil {
		return err
	}
	events, err := collect(rows, func(r pgx.Row) (*model.OrderEvent, error) {
		var e model.OrderEvent
		return &e, r.Scan(&e.ID, &e.RequestID, &e.Kind, &e.Actor, &e.CreatedAt)
	})
	for _, e := range events {
		byID[e.RequestID].Events = append(byID[e.RequestID].Events, e)
	}
	return err
}

type NewOrder struct {
	PostID            string
	PostCaption       string
	PostThumbKey      string
	CustomerAccountID string
	DesignerID        string
	DesignerAccountID string
	Notes             string
	BudgetCents       *int64
	TargetDate        *string
	Delivery          model.Delivery
	Snapshot          model.SnapshotValues
}

func InsertOrder(ctx context.Context, tx pgx.Tx, o NewOrder) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO request (post_id, post_caption, post_thumb_key, customer_account_id, designer_id,
			designer_account_id, notes, budget_cents, target_date, delivery, snapshot)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::date, $10, $11) RETURNING id`,
		o.PostID, o.PostCaption, o.PostThumbKey, o.CustomerAccountID, o.DesignerID, o.DesignerAccountID,
		o.Notes, o.BudgetCents, o.TargetDate, mustJSON(o.Delivery), mustJSON(o.Snapshot)).Scan(&id)
	return id, err
}

// OpenOrders counts the customer's non-terminal orders, and whether one is
// for this post (flows/request.md: duplicate_request, 10 open at most).
func OpenOrders(ctx context.Context, tx pgx.Tx, customerID, postID string) (total int, forPost bool, err error) {
	err = tx.QueryRow(ctx, `SELECT count(*), coalesce(bool_or(post_id = $2), false) FROM request
		WHERE customer_account_id = $1 AND status IN ('requested', 'quoted', 'paid', 'in_progress', 'shipped', 'disputed')`,
		customerID, postID).Scan(&total, &forPost)
	return total, forPost, err
}

func CountOrdersToday(ctx context.Context, tx pgx.Tx, customerID string) (int, error) {
	var n int
	err := tx.QueryRow(ctx, `SELECT count(*) FROM request WHERE customer_account_id = $1 AND created_at > now() - interval '1 day'`,
		customerID).Scan(&n)
	return n, err
}

// OrderChange is the column updates that go with a transition.
type OrderChange struct {
	QuoteCents    *int64
	DueAt         *time.Time
	Tracking      *string
	DeclineReason *string
	DisputeReason *string
	DisputeDetail *string
}

// Transition moves an order and appends its event. The caller checked the
// edge (order-lifecycle.md §1). It returns the event id, which commerce
// uses as its idempotency reference.
func Transition(ctx context.Context, tx pgx.Tx, id, from, to, actor string, c OrderChange) (string, time.Time, error) {
	tag, err := tx.Exec(ctx, `UPDATE request SET status = $3,
			quote_cents = coalesce($4, quote_cents), due_at = coalesce($5, due_at), tracking = coalesce($6, tracking),
			decline_reason = coalesce($7, decline_reason), dispute_reason = coalesce($8, dispute_reason),
			dispute_detail = coalesce($9, dispute_detail),
			quoted_at = CASE WHEN $3 = 'quoted' THEN now() ELSE quoted_at END,
			shipped_at = CASE WHEN $3 = 'shipped' THEN now() ELSE shipped_at END,
			terminal_at = CASE WHEN $3 IN ('delivered', 'refunded', 'declined', 'cancelled') THEN now() ELSE terminal_at END
		WHERE id = $1 AND status = $2`, id, from, to, c.QuoteCents, c.DueAt, c.Tracking, c.DeclineReason, c.DisputeReason, c.DisputeDetail)
	if err != nil {
		return "", time.Time{}, err
	}
	if tag.RowsAffected() == 0 {
		return "", time.Time{}, ErrConflict
	}
	return AddOrderEvent(ctx, tx, id, to, actor)
}

// Requote replaces a quote without a transition (flows/designer.md §2).
func Requote(ctx context.Context, tx pgx.Tx, id string, quote int64, due time.Time) error {
	_, err := tx.Exec(ctx, `UPDATE request SET quote_cents = $2, due_at = $3, quoted_at = now() WHERE id = $1 AND status = 'quoted'`, id, quote, due)
	return err
}

func AddOrderEvent(ctx context.Context, tx pgx.Tx, requestID, kind, actor string) (string, time.Time, error) {
	var id string
	var at time.Time
	err := tx.QueryRow(ctx, `INSERT INTO order_event (request_id, kind, actor) VALUES ($1, $2, $3) RETURNING id, created_at`,
		requestID, kind, actor).Scan(&id, &at)
	return id, at, err
}

func HasOrderEvent(ctx context.Context, tx pgx.Tx, requestID, kind string) (bool, error) {
	var on bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM order_event WHERE request_id = $1 AND kind = $2)`, requestID, kind).Scan(&on)
	return on, err
}

// ── Threads (order-lifecycle.md §5) ─────────────────────────────────────

type MessageRow struct {
	model.ThreadMessage
	MediaKey *string
}

func ListMessages(ctx context.Context, tx pgx.Tx, requestID string, offset, limit int) ([]MessageRow, error) {
	rows, err := tx.Query(ctx, `SELECT t.id, t.request_id,
			CASE WHEN t.author_is_designer THEN r.designer_id::text ELSE t.author_account_id::text END,
			t.body, m.object_key, t.created_at
		FROM thread_message t JOIN request r ON r.id = t.request_id LEFT JOIN media m ON m.id = t.media_id
		WHERE t.request_id = $1 ORDER BY t.created_at, t.id OFFSET $2 LIMIT $3`, requestID, offset, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*MessageRow, error) {
		var m MessageRow
		return &m, r.Scan(&m.ID, &m.RequestID, &m.AuthorID, &m.Body, &m.MediaKey, &m.CreatedAt)
	})
}

func InsertMessage(ctx context.Context, tx pgx.Tx, requestID, authorAccountID string, byDesigner bool, body string, mediaID *string) (string, time.Time, error) {
	var id string
	var at time.Time
	err := tx.QueryRow(ctx, `INSERT INTO thread_message (request_id, author_account_id, author_is_designer, body, media_id)
		VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at`, requestID, authorAccountID, byDesigner, body, mediaID).Scan(&id, &at)
	return id, at, err
}

// ── Sweeps (§6.7) ───────────────────────────────────────────────────────

// DueOrders lists order ids in a status whose clock column is older than age.
func DueOrders(ctx context.Context, tx pgx.Tx, status, clock string, age time.Duration) ([]string, error) {
	col := map[string]string{"quoted_at": "quoted_at", "shipped_at": "shipped_at", "paid": "created_at"}[clock]
	if status == "paid" {
		// Escrow timeout counts from the paid event.
		return ids(ctx, tx, `SELECT r.id::text FROM request r WHERE r.status = 'paid' AND
			(SELECT max(e.created_at) FROM order_event e WHERE e.request_id = r.id AND e.kind = 'paid') < now() - make_interval(secs => $1)`,
			age.Seconds())
	}
	return ids(ctx, tx, `SELECT id::text FROM request WHERE status = $1 AND `+col+` < now() - make_interval(secs => $2)`, status, age.Seconds())
}

// PruneThreads deletes messages of orders terminal for longer than age.
func PruneThreads(ctx context.Context, tx pgx.Tx, age time.Duration) (int64, error) {
	tag, err := tx.Exec(ctx, `DELETE FROM thread_message t USING request r WHERE r.id = t.request_id
		AND r.terminal_at < now() - make_interval(secs => $1)`, age.Seconds())
	return tag.RowsAffected(), err
}
