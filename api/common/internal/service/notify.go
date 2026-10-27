package service

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// prefFor maps a notification kind to the toggle that gates it (pages.md
// B7). Kinds without a toggle always go out.
func prefFor(kind string, p model.NotificationPrefs) bool {
	switch kind {
	case "quote":
		return p.Quotes
	case "status_change":
		return p.OrderStatus
	case "like", "follow", "comment":
		return p.Social
	case "payout":
		return p.Payouts
	}
	return true
}

type note struct {
	To         string // account id
	Kind       string
	PayloadRef string
	RefKind    string // request | post | session | account
	Text       string
	Actor      *model.Actor
	ThumbKey   *string
	Money      *money
	// Email marks money events, which commerce mirrors by email (§6.5).
	Email bool
}

type money struct {
	Amount   int64  `json:"amount"`
	Currency string `json:"currency"`
}

// notify writes the NOTIFICATION row (the source of truth, data-model.md
// §6.4) in the caller's transaction, and queues its delivery for commerce.
// A disabled preference drops the event for that recipient, as in the mock.
func notify(ctx context.Context, tx pgx.Tx, n note) error {
	return repository.Bypass(ctx, tx, func() error {
		to, err := repository.LoadAccountNotify(ctx, tx, n.To)
		if err != nil {
			return err
		}
		if !prefFor(n.Kind, to.Prefs) {
			return nil
		}
		id, at, err := repository.InsertNotification(ctx, tx, repository.NewNotification{
			AccountID: n.To, Kind: n.Kind, PayloadRef: n.PayloadRef, Text: n.Text, Actor: n.Actor, ThumbKey: n.ThumbKey,
		})
		if err != nil {
			return err
		}
		tokens, err := repository.DeviceTokens(ctx, tx, n.To)
		if err != nil {
			return err
		}
		if tokens == nil {
			tokens = []string{}
		}
		recipient := map[string]any{"push_tokens": tokens, "display_name": to.DisplayName}
		if n.Email {
			recipient["email"] = to.Email
		}
		msg := map[string]any{
			"notification_id": id, "account_id": n.To, "kind": n.Kind, "created_at": at.UTC().Format(time.RFC3339Nano),
			"ref": map[string]string{"kind": n.RefKind, "id": n.PayloadRef}, "text": n.Text, "recipient": recipient,
		}
		if n.Money != nil {
			msg["money"] = n.Money
		}
		return repository.Enqueue(ctx, tx, kafka.EventNotificationsCreated, n.To, msg)
	})
}

// Notifications is the activity sheet (C10/B-activity).
func (s *Services) Notifications(ctx context.Context, p *Principal, pg Paging) (any, error) {
	var list []model.Notification
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		list, err = repository.ListNotifications(ctx, tx, p.AccountID, pg.Offset, pg.Limit+1)
		return err
	})
	for i := range list {
		list[i].ThumbURL = s.thumb(ctx, list[i].ThumbKey)
	}
	return page(list, pg), err
}

func (s *Services) MarkNotificationsRead(ctx context.Context, p *Principal, ids []string) error {
	return s.as(ctx, p, func(tx pgx.Tx) error { return repository.MarkRead(ctx, tx, p.AccountID, ids) })
}

func (s *Services) SetDevice(ctx context.Context, p *Principal, token, platform string) error {
	if token == "" || (platform != "android" && platform != "ios" && platform != "web") {
		return invalid("token and platform (android|ios|web) are required")
	}
	return s.as(ctx, p, func(tx pgx.Tx) error { return repository.SetDeviceToken(ctx, tx, p.AccountID, token, platform) })
}

func (s *Services) RemoveDevice(ctx context.Context, p *Principal, token string) error {
	return s.as(ctx, p, func(tx pgx.Tx) error { return repository.DeleteDeviceToken(ctx, tx, p.AccountID, token) })
}
