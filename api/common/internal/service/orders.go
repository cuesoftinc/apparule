package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// transitions is order-lifecycle.md §1; web/src/models/entities/order.ts
// is the client copy.
var transitions = map[string][]string{
	"requested":   {"quoted", "declined", "cancelled"},
	"quoted":      {"paid", "cancelled"},
	"paid":        {"in_progress", "refunded", "disputed"},
	"in_progress": {"shipped", "disputed"},
	"shipped":     {"delivered", "disputed"},
	"disputed":    {"delivered", "refunded"},
}

func canTransition(from, to string) bool {
	for _, t := range transitions[from] {
		if t == to {
			return true
		}
	}
	return false
}

func invalidTransition(from, to string) *Error {
	return conflict("invalid_transition", fmt.Sprintf("Cannot move an order from %s to %s", from, to))
}

func (s *Services) Orders(ctx context.Context, p *Principal, role string, pg Paging) (any, error) {
	var list []model.Order
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		rows, err := repository.ListOrders(ctx, tx, p.AccountID, role, pg.Offset, pg.Limit+1)
		for _, o := range rows {
			list = append(list, o.Order)
		}
		return err
	})
	return page(list, pg), err
}

func (s *Services) Order(ctx context.Context, p *Principal, id string) (*model.Order, error) {
	var out *model.Order
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		o, err := repository.GetOrder(ctx, tx, id)
		if err == nil {
			out = &o.Order
		}
		return err
	})
	return out, err
}

type RequestInput struct {
	SessionID   string          `json:"session_id"`
	Notes       string          `json:"notes"`
	BudgetCents *int64          `json:"budget_cents"`
	TargetDate  *string         `json:"target_date"`
	Delivery    *model.Delivery `json:"delivery"`
}

// CreateRequest submits a commission with a frozen measurement snapshot
// (flows/request.md; order-lifecycle.md §1).
func (s *Services) CreateRequest(ctx context.Context, p *Principal, postID string, in RequestInput) (*model.Order, error) {
	if err := active(p); err != nil {
		return nil, err
	}
	d := in.Delivery
	if d == nil || d.RecipientName == "" || d.Phone == "" || d.Line1 == "" || d.City == "" || d.State == "" || d.Country == "" {
		return nil, invalid("Delivery address is incomplete")
	}
	if len(in.Notes) > 1000 {
		return nil, invalid("Notes are at most 1000 characters")
	}
	if in.TargetDate != nil {
		if _, err := time.Parse("2006-01-02", *in.TargetDate); err != nil {
			return nil, invalid("target_date must be YYYY-MM-DD")
		}
	}
	var out *model.Order
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		author, err := s.visiblePost(ctx, tx, p, postID)
		if err != nil {
			return err
		}
		designer, err := repository.DesignerByID(ctx, tx, author.DesignerID)
		if err != nil {
			return err
		}
		// A-2: posts of designers without verified KYC don't take requests.
		if designer.PayoutAccount.KYCState != "verified" || author.AccountID == p.AccountID {
			return conflict("post_unavailable", "This outfit is no longer available")
		}
		session, err := repository.GetSession(ctx, tx, in.SessionID)
		if err != nil || session.CustomerID != p.SelfCustomerID || session.Status != "complete" {
			return &Error{Status: http.StatusUnprocessableEntity, Code: "snapshot_invalid", Message: "The selected measurement session is not usable"}
		}
		open, forPost, err := repository.OpenOrders(ctx, tx, p.AccountID, postID)
		if err != nil {
			return err
		}
		if forPost {
			return conflict("duplicate_request", "You already have an open request for this outfit")
		}
		today, err := repository.CountOrdersToday(ctx, tx, p.AccountID)
		if err != nil {
			return err
		}
		if open >= s.Config.Limits.OpenRequests || today >= s.Config.Limits.RequestsPerDay {
			return rateLimited(time.Hour, "You have too many open requests")
		}
		// Frozen copy: later vault changes never mutate an order (§5).
		values := model.SnapshotValues{Method: session.Method, MeasuredAt: session.CreatedAt, Measurements: latestValues(session.Measurements)}
		thumb := ""
		if author.ThumbKey != nil {
			thumb = s.mediaURL(*author.ThumbKey)
		}
		id, err := repository.InsertOrder(ctx, tx, repository.NewOrder{
			PostID: postID, PostCaption: author.Caption, PostThumbURL: thumb, CustomerAccountID: p.AccountID,
			DesignerID: designer.ID, DesignerAccountID: designer.AccountID, Notes: in.Notes, BudgetCents: in.BudgetCents,
			TargetDate: in.TargetDate, Delivery: *d, Snapshot: values,
		})
		if err != nil {
			return err
		}
		eventID, at, err := repository.AddOrderEvent(ctx, tx, id, "requested", "customer")
		if err != nil {
			return err
		}
		o, err := repository.GetOrder(ctx, tx, id)
		if err != nil {
			return err
		}
		if err := s.publishTransition(ctx, tx, o, "", "requested", "customer", eventID, at); err != nil {
			return err
		}
		title, _, _ := strings.Cut(author.Caption, " — ")
		if err := notify(ctx, tx, note{To: designer.AccountID, Kind: "status_change", PayloadRef: id, RefKind: "request",
			Text: fmt.Sprintf("%s requested %s (#%s)", p.Username, title, o.OrderNumber), Actor: s.actor(ctx, tx, p), ThumbURL: optional(thumb)}); err != nil {
			return err
		}
		out = &o.Order
		return nil
	})
	return out, err
}

// latestValues collapses corrections onto their measure: the snapshot
// carries the value a tailor should use, one per name, in session order.
func latestValues(ms []model.Measurement) []model.SnapshotValue {
	index := map[string]int{}
	out := []model.SnapshotValue{}
	for _, m := range ms {
		if i, ok := index[m.Name]; ok {
			out[i].ValueCM = m.ValueCM
			continue
		}
		index[m.Name] = len(out)
		out = append(out, model.SnapshotValue{Name: m.Name, ValueCM: m.ValueCM})
	}
	return out
}

// orderAction loads an order for an actor and runs fn under its row lock.
func (s *Services) orderAction(ctx context.Context, p *Principal, id, role string, fn func(tx pgx.Tx, o *repository.OrderRow) error) (*model.Order, error) {
	var out *model.Order
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		o, err := repository.LockOrder(ctx, tx, id)
		if err != nil {
			return err
		}
		switch role {
		case "customer":
			if o.CustomerAccountID != p.AccountID {
				return repository.ErrNotFound
			}
		case "designer":
			if o.DesignerAccountID != p.AccountID {
				return repository.ErrNotFound
			}
		}
		if err := fn(tx, o); err != nil {
			return err
		}
		o, err = repository.GetOrder(ctx, tx, id)
		if err == nil {
			out = &o.Order
		}
		return err
	})
	return out, err
}

// move applies a transition, publishes it for commerce, and notifies.
func (s *Services) move(ctx context.Context, tx pgx.Tx, o *repository.OrderRow, to, actor string, change repository.OrderChange) error {
	if !canTransition(o.Status, to) {
		return invalidTransition(o.Status, to)
	}
	eventID, at, err := repository.Transition(ctx, tx, o.ID, o.Status, to, actor, change)
	if errors.Is(err, repository.ErrConflict) {
		return invalidTransition(o.Status, to)
	}
	if err != nil {
		return err
	}
	from := o.Status
	o.Status = to
	if change.QuoteCents != nil {
		o.QuoteCents = change.QuoteCents
	}
	return s.publishTransition(ctx, tx, o, from, to, actor, eventID, at)
}

// publishTransition queues orders.transition (§6.3). commerce acts on the
// money edges; it gets everything a decision needs in the message.
func (s *Services) publishTransition(ctx context.Context, tx pgx.Tx, o *repository.OrderRow, from, to, actor, eventID string, at time.Time) error {
	if from == "" {
		return nil // creation is not a transition commerce cares about
	}
	msg := map[string]any{"request_id": o.ID, "transition_id": eventID, "from": from, "to": to, "actor": actor,
		"occurred_at": at.UTC().Format(time.RFC3339Nano)}
	if o.QuoteCents != nil {
		msg["quote"] = money{Amount: *o.QuoteCents, Currency: o.Currency}
	}
	if o.Payment != nil && o.Reference != nil && o.Payment.State != "pending" {
		pay := map[string]any{"reference": *o.Reference, "amount": money{Amount: o.Payment.AmountCents, Currency: o.Payment.Currency}}
		if o.ProviderRef != nil {
			pay["provider_transaction_id"] = *o.ProviderRef
		}
		msg["payment"] = pay
	}
	if to == "delivered" && o.RecipientCode != nil {
		msg["payout_recipient"] = map[string]string{"recipient_code": *o.RecipientCode}
	}
	return repository.Enqueue(ctx, tx, kafka.EventOrdersTransition, o.ID, msg)
}

// partyNote notifies the other party of a transition.
func (s *Services) partyNote(ctx context.Context, tx pgx.Tx, o *repository.OrderRow, to, kind, text string, actor *model.Actor) error {
	return notify(ctx, tx, note{To: to, Kind: kind, PayloadRef: o.ID, RefKind: "request", Text: text, Actor: actor,
		ThumbURL: optional(o.Post.ThumbURL)})
}

func (s *Services) Cancel(ctx context.Context, p *Principal, id string) (*model.Order, error) {
	return s.orderAction(ctx, p, id, "customer", func(tx pgx.Tx, o *repository.OrderRow) error {
		if err := s.move(ctx, tx, o, "cancelled", "customer", repository.OrderChange{}); err != nil {
			return err
		}
		return s.partyNote(ctx, tx, o, o.DesignerAccountID, "status_change",
			fmt.Sprintf("%s cancelled request #%s", o.Customer.Username, o.OrderNumber), &model.Actor{Username: o.Customer.Username})
	})
}

// Quote quotes (requested -> quoted) or requotes while quoted (flows/
// designer.md §2).
func (s *Services) Quote(ctx context.Context, p *Principal, id string, quoteCents int64, dueAt string) (*model.Order, error) {
	if quoteCents <= 0 {
		return nil, invalid("quote_cents must be a positive integer")
	}
	due, err := time.Parse(time.RFC3339, dueAt)
	if err != nil {
		if d, err2 := time.Parse("2006-01-02", dueAt); err2 == nil {
			due = d
		} else {
			return nil, invalid("due_at must be a date")
		}
	}
	return s.orderAction(ctx, p, id, "designer", func(tx pgx.Tx, o *repository.OrderRow) error {
		if o.Status == "quoted" {
			if err := repository.Requote(ctx, tx, o.ID, quoteCents, due); err != nil {
				return err
			}
		} else if err := s.move(ctx, tx, o, "quoted", "designer", repository.OrderChange{QuoteCents: &quoteCents, DueAt: &due}); err != nil {
			return err
		}
		return s.partyNote(ctx, tx, o, o.CustomerAccountID, "quote",
			fmt.Sprintf("%s quoted your request #%s", o.Designer.Username, o.OrderNumber), &model.Actor{Username: o.Designer.Username})
	})
}

var declineReasons = map[string]bool{"workload": true, "out_of_specialty": true, "budget_too_low": true, "timeline_too_tight": true, "other": true}

func (s *Services) Decline(ctx context.Context, p *Principal, id, reason string) (*model.Order, error) {
	if !declineReasons[reason] {
		return nil, invalid("Decline reason is required")
	}
	return s.orderAction(ctx, p, id, "designer", func(tx pgx.Tx, o *repository.OrderRow) error {
		if err := s.move(ctx, tx, o, "declined", "designer", repository.OrderChange{DeclineReason: &reason}); err != nil {
			return err
		}
		return s.partyNote(ctx, tx, o, o.CustomerAccountID, "status_change",
			fmt.Sprintf("%s declined request #%s", o.Designer.Username, o.OrderNumber), &model.Actor{Username: o.Designer.Username})
	})
}

func (s *Services) SetStatus(ctx context.Context, p *Principal, id, status string, tracking *string) (*model.Order, error) {
	if status != "in_progress" && status != "shipped" {
		return nil, invalid("status must be in_progress or shipped")
	}
	return s.orderAction(ctx, p, id, "designer", func(tx pgx.Tx, o *repository.OrderRow) error {
		change := repository.OrderChange{}
		if status == "shipped" && tracking != nil && *tracking != "" {
			change.Tracking = tracking
		}
		if err := s.move(ctx, tx, o, status, "designer", change); err != nil {
			return err
		}
		text := fmt.Sprintf("%s started work on your order #%s", o.Designer.Username, o.OrderNumber)
		if status == "shipped" {
			text = "Order #" + o.OrderNumber + " shipped"
			if change.Tracking != nil {
				text += " — " + *change.Tracking
			}
		}
		return s.partyNote(ctx, tx, o, o.CustomerAccountID, "status_change", text, &model.Actor{Username: o.Designer.Username})
	})
}

// Pay starts the Paystack checkout of a quoted order. The order becomes
// paid only when commerce settles the charge from Paystack's webhook
// (§6.3), never on the client's word.
func (s *Services) Pay(ctx context.Context, p *Principal, id string) (*model.Order, error) {
	if s.Config.Paystack.PublicKey == "" {
		return nil, newErr(http.StatusServiceUnavailable, "provider_unavailable", "Payments are not configured")
	}
	return s.orderActionWith(ctx, p, id, func(tx pgx.Tx, o *repository.OrderRow, out *model.Order) error {
		if o.Status != "quoted" || o.QuoteCents == nil {
			return conflict("invalid_transition", "Only a quoted order can be paid")
		}
		reference := "apr_" + strings.ReplaceAll(o.ID, "-", "")
		ref, err := repository.StartPayment(ctx, tx, o.ID, reference, o.Currency, *o.QuoteCents)
		if err != nil {
			return err
		}
		out.Checkout = &model.Checkout{Provider: "paystack", Reference: ref, AmountCents: *o.QuoteCents, Currency: o.Currency,
			Email: p.Email, PublicKey: s.Config.Paystack.PublicKey}
		return nil
	})
}

func (s *Services) orderActionWith(ctx context.Context, p *Principal, id string, fn func(tx pgx.Tx, o *repository.OrderRow, out *model.Order) error) (*model.Order, error) {
	var checkout *model.Checkout
	o, err := s.orderAction(ctx, p, id, "customer", func(tx pgx.Tx, o *repository.OrderRow) error {
		var tmp model.Order
		err := fn(tx, o, &tmp)
		checkout = tmp.Checkout
		return err
	})
	if o != nil {
		o.Checkout = checkout
	}
	return o, err
}

func (s *Services) ConfirmDelivery(ctx context.Context, p *Principal, id string) (*model.Order, error) {
	return s.orderAction(ctx, p, id, "customer", func(tx pgx.Tx, o *repository.OrderRow) error {
		return s.deliver(ctx, tx, o, "customer")
	})
}

// deliver moves an order to delivered; commerce releases the payout.
func (s *Services) deliver(ctx context.Context, tx pgx.Tx, o *repository.OrderRow, actor string) error {
	if err := s.move(ctx, tx, o, "delivered", actor, repository.OrderChange{}); err != nil {
		return err
	}
	return s.partyNote(ctx, tx, o, o.CustomerAccountID, "status_change",
		fmt.Sprintf("Order #%s marked delivered", o.OrderNumber), nil)
}

var disputeReasons = map[string]bool{"not_received": true, "not_as_described": true, "size_wrong": true, "other": true}

// Dispute freezes the payout (either party, before delivery confirm).
func (s *Services) Dispute(ctx context.Context, p *Principal, id, reason string, detail *string) (*model.Order, error) {
	if !disputeReasons[reason] {
		return nil, invalid("A valid dispute reason is required")
	}
	return s.orderAction(ctx, p, id, "party", func(tx pgx.Tx, o *repository.OrderRow) error {
		actor, other := "customer", o.DesignerAccountID
		if o.DesignerAccountID == p.AccountID {
			actor, other = "designer", o.CustomerAccountID
		}
		if err := s.move(ctx, tx, o, "disputed", actor, repository.OrderChange{DisputeReason: &reason, DisputeDetail: detail}); err != nil {
			return err
		}
		return s.partyNote(ctx, tx, o, other, "status_change", fmt.Sprintf("Order #%s is under dispute", o.OrderNumber), nil)
	})
}

// ResolveDispute is support's call (order-lifecycle.md §2): delivered
// releases the payout, refunded refunds the customer.
func (s *Services) ResolveDispute(ctx context.Context, p *Principal, id, outcome string) (*model.Order, error) {
	if !p.IsStaff {
		return nil, newErr(http.StatusForbidden, "forbidden", "Dispute resolution is staff-only")
	}
	if outcome != "delivered" && outcome != "refunded" {
		return nil, invalid("outcome must be delivered or refunded")
	}
	var out *model.Order
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		o, err := repository.LockOrder(ctx, tx, id)
		if err != nil {
			return err
		}
		if o.Status != "disputed" {
			return conflict("invalid_transition", "Only a disputed order can be resolved")
		}
		if err := s.move(ctx, tx, o, outcome, "moderator", repository.OrderChange{}); err != nil {
			return err
		}
		for _, to := range []string{o.CustomerAccountID, o.DesignerAccountID} {
			if err := s.partyNote(ctx, tx, o, to, "status_change", fmt.Sprintf("The dispute on order #%s was resolved", o.OrderNumber), nil); err != nil {
				return err
			}
		}
		o, err = repository.GetOrder(ctx, tx, id)
		if err == nil {
			out = &o.Order
		}
		return err
	})
	return out, err
}

// ── Threads ─────────────────────────────────────────────────────────────

func (s *Services) Messages(ctx context.Context, p *Principal, id string, pg Paging) (any, error) {
	var list []model.ThreadMessage
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if _, err := repository.GetOrder(ctx, tx, id); err != nil {
			return err // party check (RLS)
		}
		rows, err := repository.ListMessages(ctx, tx, id, pg.Offset, pg.Limit+1)
		if err != nil {
			return err
		}
		for _, m := range rows {
			msg := m.ThreadMessage
			if m.MediaKey != nil {
				url, err := s.Store.SignedURL(ctx, *m.MediaKey, time.Hour)
				if err != nil {
					return err
				}
				msg.ImageURL = &url
			}
			list = append(list, msg)
		}
		return nil
	})
	return page(list, pg), err
}

// AddMessage posts to an order thread (≤ 1000 chars; images only as
// attachments uploaded through a ticket; order-lifecycle.md §5).
func (s *Services) AddMessage(ctx context.Context, p *Principal, id, body string, imageURL *string) (*model.ThreadMessage, error) {
	body = strings.TrimSpace(body)
	if body == "" || len([]rune(body)) > 1000 {
		return nil, invalid("Message body must be 1-1000 characters")
	}
	var out *model.ThreadMessage
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		o, err := repository.GetOrder(ctx, tx, id)
		if err != nil {
			return err
		}
		byDesigner := o.DesignerAccountID == p.AccountID
		other := o.DesignerAccountID
		if byDesigner {
			other = o.CustomerAccountID
		}
		// Blocks lock the thread to order-essential messages; here that
		// means the thread stays open but no new attachments (§6.2).
		blocked, err := repository.Blocked(ctx, tx, p.AccountID, other)
		if err != nil {
			return err
		}
		var mediaID *string
		var mediaKey *string
		if imageURL != nil && *imageURL != "" {
			if blocked {
				return newErr(http.StatusForbidden, "forbidden", "Attachments are off for this thread")
			}
			mid := mediaIDFromURL(*imageURL)
			rows, err := repository.GetMedia(ctx, tx, []string{mid})
			if err != nil {
				return err
			}
			if len(rows) != 1 || rows[0].AccountID != p.AccountID || rows[0].Kind != "attachment" ||
				rows[0].RequestID == nil || *rows[0].RequestID != id {
				return invalid("Attach an image you uploaded for this order")
			}
			mediaID, mediaKey = &mid, &rows[0].Key
			if rows[0].Stage == "tmp" {
				dst := fmt.Sprintf("%s/attachments/%s/%s.jpg", s.Store.Prefix(), id, mid)
				if err := s.Store.Copy(ctx, rows[0].Key, dst); err != nil {
					return err
				}
				if err := repository.ConfirmMedia(ctx, tx, mid, dst); err != nil {
					return err
				}
				_ = s.Store.Delete(ctx, rows[0].Key)
				mediaKey = &dst
			}
		}
		msgID, at, err := repository.InsertMessage(ctx, tx, id, p.AccountID, byDesigner, body, mediaID)
		if err != nil {
			return err
		}
		author := p.AccountID
		if byDesigner {
			author = o.Designer.ID
		}
		out = &model.ThreadMessage{ID: msgID, RequestID: id, AuthorID: author, Body: body, CreatedAt: at}
		if mediaKey != nil {
			url, err := s.Store.SignedURL(ctx, *mediaKey, time.Hour)
			if err != nil {
				return err
			}
			out.ImageURL = &url
		}
		return nil
	})
	return out, err
}

// StartAttachment reserves an attachment upload for a party of the order.
func (s *Services) StartAttachment(ctx context.Context, p *Principal, id string) (*model.MediaBatch, error) {
	if err := s.as(ctx, p, func(tx pgx.Tx) error {
		_, err := repository.GetOrder(ctx, tx, id)
		return err
	}); err != nil {
		return nil, err
	}
	return s.startBatch(ctx, p, "attachment", &id, 1)
}

// ── Designer earnings and payout account (pages.md B8, B9) ──────────────

func (s *Services) Earnings(ctx context.Context, p *Principal) (*model.Earnings, error) {
	designerID, err := requireDesigner(p, "Earnings are available to designer profiles only")
	if err != nil {
		return nil, err
	}
	var out *model.Earnings
	err = s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		out, err = repository.Earnings(ctx, tx, designerID)
		return err
	})
	return out, err
}

// banks is the seeded NG list (pages.md B8); the display name is what
// payout surfaces show, never the CBN code.
var banks = map[string]string{"058": "GTBank", "044": "Access Bank", "057": "Zenith Bank", "011": "First Bank", "033": "UBA"}

// SubmitPayoutAccount starts verifying a bank account: commerce resolves
// the name with Paystack and creates the transfer recipient, and the
// profile reads pending until its outcome arrives (pages.md B8 states).
func (s *Services) SubmitPayoutAccount(ctx context.Context, p *Principal, bankCode, accountNumber string) (*model.PayoutAccount, error) {
	designerID, err := requireDesigner(p, "Enable a designer profile first")
	if err != nil {
		return nil, err
	}
	bank, ok := banks[bankCode]
	if !ok {
		return nil, invalid("Pick your bank")
	}
	if len(accountNumber) != 10 || strings.Trim(accountNumber, "0123456789") != "" {
		return nil, &Error{Status: http.StatusUnprocessableEntity, Code: "bank_resolution_failed", Message: "Could not resolve that account number"}
	}
	var out *model.PayoutAccount
	err = s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByID(ctx, tx, designerID)
		if err != nil {
			return err
		}
		attempt := uuid.NewString()
		if err := repository.StartPayoutAttempt(ctx, tx, designerID, attempt, bankCode, bank, accountNumber[6:]); err != nil {
			return err
		}
		if err := repository.Enqueue(ctx, tx, kafka.EventPayoutsRecipient, designerID, map[string]any{
			"designer_id": designerID, "attempt_id": attempt, "bank_code": bankCode, "account_number": accountNumber,
			"account_holder": d.DisplayName,
		}); err != nil {
			return err
		}
		d, err = repository.DesignerByID(ctx, tx, designerID)
		if err == nil {
			out = &d.PayoutAccount
		}
		return err
	})
	return out, err
}

func (s *Services) PayoutAccount(ctx context.Context, p *Principal) (*model.PayoutAccount, error) {
	designerID, err := requireDesigner(p, "Enable a designer profile first")
	if err != nil {
		return nil, err
	}
	var out *model.PayoutAccount
	err = s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByID(ctx, tx, designerID)
		if err == nil {
			out = &d.PayoutAccount
		}
		return err
	})
	return out, err
}

// ── Paystack webhooks (S-12) ────────────────────────────────────────────

var ErrBadSignature = errors.New("bad webhook signature")

// ReceiveWebhook verifies Paystack's signature, stores the raw event before
// anything acts on it, and hands it to commerce with the order its
// reference names (a lookup, not a decision).
func (s *Services) ReceiveWebhook(ctx context.Context, body []byte, signature string) error {
	if s.Config.Paystack.SecretKey == "" {
		return ErrBadSignature
	}
	mac := hmac.New(sha512.New, []byte(s.Config.Paystack.SecretKey))
	mac.Write(body)
	if !hmac.Equal([]byte(hex.EncodeToString(mac.Sum(nil))), []byte(strings.ToLower(signature))) {
		return ErrBadSignature
	}
	var evt struct {
		Event string          `json:"event"`
		Data  json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(body, &evt); err != nil || evt.Event == "" {
		return ErrBadSignature
	}
	var data struct {
		Reference string `json:"reference"`
	}
	_ = json.Unmarshal(evt.Data, &data)
	sum := sha256.Sum256(body)
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		id, received, stored, err := repository.InsertProviderEvent(ctx, tx, "paystack", hex.EncodeToString(sum[:]), evt.Event, evt.Data)
		if err != nil || !stored {
			return err // a redelivery: already handed off
		}
		var order any
		if data.Reference != "" {
			if o, err := repository.OrderByReference(ctx, tx, data.Reference); err == nil && o.QuoteCents != nil {
				order = map[string]any{"request_id": o.ID, "status": o.Status, "reference": data.Reference,
					"quote": money{Amount: *o.QuoteCents, Currency: o.Currency}}
			} else if err != nil && !errors.Is(err, repository.ErrNotFound) {
				return err
			}
		}
		payload := json.RawMessage(evt.Data)
		if len(payload) == 0 || payload[0] != '{' {
			payload = json.RawMessage(`{}`)
		}
		return repository.Enqueue(ctx, tx, kafka.EventPaymentsProviderEvent, id, map[string]any{
			"provider_event_id": id, "provider": "paystack", "event": evt.Event,
			"received_at": received.UTC().Format(time.RFC3339Nano), "payload": payload, "order": order,
		})
	})
}

// ── commerce's decisions (payments.outcome) ─────────────────────────────

type outcomeMsg struct {
	OutcomeID       string                  `json:"outcome_id"`
	Kind            string                  `json:"kind"`
	RequestID       *string                 `json:"request_id"`
	DesignerID      *string                 `json:"designer_id"`
	AttemptID       *string                 `json:"attempt_id"`
	ProviderEventID *string                 `json:"provider_event_id"`
	Reference       *string                 `json:"reference"`
	ProviderRef     *string                 `json:"provider_ref"`
	Amount          *money                  `json:"amount"`
	Fee             *money                  `json:"fee"`
	Ledger          []repository.LedgerLine `json:"ledger"`
	Recipient       *struct {
		RecipientCode string `json:"recipient_code"`
		AccountName   string `json:"account_name"`
		BankName      string `json:"bank_name"`
		Last4         string `json:"last4"`
	} `json:"recipient"`
	Reason *string `json:"reason"`
}

// OnPaymentOutcome stores a money decision as made (S-6), once.
func (s *Services) OnPaymentOutcome(ctx context.Context, raw json.RawMessage) error {
	var m outcomeMsg
	if err := json.Unmarshal(raw, &m); err != nil {
		return err
	}
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		fresh, err := repository.RecordOutcome(ctx, tx, m.OutcomeID, m.Kind, m.RequestID, m.DesignerID, m.Reason, raw)
		if err != nil || !fresh {
			return err
		}
		if m.ProviderEventID != nil {
			if err := repository.MarkProviderEvent(ctx, tx, *m.ProviderEventID, m.Kind); err != nil {
				return err
			}
		}
		switch m.Kind {
		case "recipient_verified", "recipient_failed":
			return s.storeRecipient(ctx, tx, m)
		case "mismatch", "charge_rejected", "payout_failed", "refund_failed":
			// A human resolves these (§6.4); commerce never fixes the ledger.
			slog.Error("money needs attention", "step", "payments.outcome", "kind", m.Kind, "outcome_id", m.OutcomeID,
				"request_id", deref(m.RequestID), "reason", deref(m.Reason))
			if m.Kind == "payout_failed" && m.RequestID != nil {
				o, err := repository.GetOrder(ctx, tx, *m.RequestID)
				if err != nil {
					return err
				}
				return repository.UpsertPayout(ctx, tx, o.ID, o.Designer.ID, o.Currency, "failed", 0, m.ProviderRef)
			}
			return nil
		}
		if m.RequestID == nil || m.Amount == nil {
			return nil
		}
		o, err := repository.LockOrder(ctx, tx, *m.RequestID)
		if err != nil {
			return err
		}
		if err := repository.AppendLedger(ctx, tx, m.OutcomeID, o.ID, m.Amount.Currency, m.Ledger); err != nil {
			return err
		}
		switch m.Kind {
		case "charge_settled":
			var fee *int64
			if m.Fee != nil {
				fee = &m.Fee.Amount
			}
			if err := repository.SetPaymentState(ctx, tx, o.ID, "held", fee, m.ProviderRef); err != nil {
				return err
			}
			o.Payment = &model.Payment{State: "held", AmountCents: m.Amount.Amount, Currency: m.Amount.Currency}
			o.ProviderRef = m.ProviderRef
			if o.Status != "quoted" {
				// The order stopped being payable between checkout and the
				// webhook (quote expired, say). The money is held; a human
				// refunds it. Never fail the consumer over it.
				slog.Error("charge settled for an order that is no longer payable", "step", "payments.outcome",
					"request_id", o.ID, "status", o.Status, "outcome_id", m.OutcomeID)
				return nil
			}
			if err := s.move(ctx, tx, o, "paid", "customer", repository.OrderChange{}); err != nil {
				return err
			}
			if err := notify(ctx, tx, note{To: o.CustomerAccountID, Kind: "status_change", PayloadRef: o.ID, RefKind: "request",
				Text: fmt.Sprintf("Payment received for order #%s", o.OrderNumber), Money: m.Amount, Email: true}); err != nil {
				return err
			}
			return notify(ctx, tx, note{To: o.DesignerAccountID, Kind: "status_change", PayloadRef: o.ID, RefKind: "request",
				Text: fmt.Sprintf("Order #%s is funded — start work", o.OrderNumber), Money: m.Amount, Email: true})
		case "payout_released":
			if err := repository.SetPaymentState(ctx, tx, o.ID, "released", nil, nil); err != nil {
				return err
			}
			if err := repository.UpsertPayout(ctx, tx, o.ID, o.Designer.ID, m.Amount.Currency, "paid", m.Amount.Amount, m.ProviderRef); err != nil {
				return err
			}
			return notify(ctx, tx, note{To: o.DesignerAccountID, Kind: "payout", PayloadRef: o.ID, RefKind: "request",
				Text: fmt.Sprintf("Payout released for order #%s", o.OrderNumber), Money: m.Amount, Email: true})
		case "refund_issued":
			if err := repository.SetPaymentState(ctx, tx, o.ID, "refunded", nil, nil); err != nil {
				return err
			}
			return notify(ctx, tx, note{To: o.CustomerAccountID, Kind: "status_change", PayloadRef: o.ID, RefKind: "request",
				Text: fmt.Sprintf("Order #%s was refunded", o.OrderNumber), Money: m.Amount, Email: true})
		}
		return nil
	})
}

func (s *Services) storeRecipient(ctx context.Context, tx pgx.Tx, m outcomeMsg) error {
	if m.DesignerID == nil || m.AttemptID == nil {
		return nil
	}
	verified := m.Kind == "recipient_verified"
	var code, name, bank, last4 *string
	if m.Recipient != nil {
		code, name, bank, last4 = &m.Recipient.RecipientCode, &m.Recipient.AccountName, &m.Recipient.BankName, &m.Recipient.Last4
	}
	_, err := repository.FinishPayoutAttempt(ctx, tx, *m.DesignerID, *m.AttemptID, verified, code, name, bank, last4, m.Reason)
	return err
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
