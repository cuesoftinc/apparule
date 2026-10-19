package service

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// These run inside the sweep's system transaction (sweep package, §6.7).

// ResendCapture queues capture.ready again, once, for a capture whose result
// is overdue: the shared bus may have dropped it (X-11).
func (s *Services) ResendCapture(ctx context.Context, tx pgx.Tx, id string) error {
	row, err := repository.LockSession(ctx, tx, id)
	if err != nil {
		return err
	}
	if row.Status != "processing" || row.ResentAt != nil {
		return nil
	}
	if err := s.sendCaptureReady(ctx, tx, row, row.Attempt); err != nil {
		return err
	}
	now := s.Now()
	// sendCaptureReady restarted the clock; keep the original start so the
	// fail deadline still counts from the first send.
	return repository.UpdateSession(ctx, tx, id, repository.SessionUpdate{Status: "processing", ResentAt: &now, ProcessingSince: row.Processing})
}

// ExpireQuote cancels a quote left for 7 days (A-7) and tells both parties.
func (s *Services) ExpireQuote(ctx context.Context, tx pgx.Tx, id string) error {
	o, err := repository.LockOrder(ctx, tx, id)
	if err != nil {
		return err
	}
	if err := s.move(ctx, tx, o, "cancelled", "system", repository.OrderChange{}); err != nil {
		return err
	}
	text := fmt.Sprintf("The quote on order #%s expired", o.OrderNumber)
	if err := s.partyNote(ctx, tx, o, o.CustomerAccountID, "status_change", text, nil); err != nil {
		return err
	}
	return s.partyNote(ctx, tx, o, o.DesignerAccountID, "status_change", text, nil)
}

// EscrowTimeout refunds an order paid 14 days ago and never started; the
// designer is told (order-lifecycle.md §1 "Escrow never waits forever").
func (s *Services) EscrowTimeout(ctx context.Context, tx pgx.Tx, id string) error {
	o, err := repository.LockOrder(ctx, tx, id)
	if err != nil {
		return err
	}
	if err := s.move(ctx, tx, o, "refunded", "system", repository.OrderChange{}); err != nil {
		return err
	}
	if err := s.partyNote(ctx, tx, o, o.DesignerAccountID, "status_change",
		fmt.Sprintf("Order #%s was refunded: work didn't start within 14 days", o.OrderNumber), nil); err != nil {
		return err
	}
	return s.partyNote(ctx, tx, o, o.CustomerAccountID, "status_change",
		fmt.Sprintf("Order #%s is being refunded", o.OrderNumber), nil)
}

// AutoConfirm delivers an order shipped 14 days ago (A-7).
func (s *Services) AutoConfirm(ctx context.Context, tx pgx.Tx, id string) error {
	o, err := repository.LockOrder(ctx, tx, id)
	if err != nil {
		return err
	}
	return s.deliver(ctx, tx, o, "system")
}

// Remind sends a reminder once per kind: the customer's T+7 and T+12
// delivery reminders, and the quote's T-2d expiry reminder.
func (s *Services) Remind(ctx context.Context, tx pgx.Tx, id, kind string) error {
	done, err := repository.HasOrderEvent(ctx, tx, id, kind)
	if err != nil || done {
		return err
	}
	o, err := repository.GetOrder(ctx, tx, id)
	if err != nil {
		return err
	}
	if _, _, err := repository.AddOrderEvent(ctx, tx, id, kind, "system"); err != nil {
		return err
	}
	text := fmt.Sprintf("Did order #%s arrive? Confirm delivery, or it confirms automatically", o.OrderNumber)
	noteKind := "status_change"
	if kind == "quote_reminder" {
		text = fmt.Sprintf("Your quote for order #%s expires in 2 days", o.OrderNumber)
		noteKind = "quote"
	}
	return s.partyNote(ctx, tx, o, o.CustomerAccountID, noteKind, text, nil)
}
