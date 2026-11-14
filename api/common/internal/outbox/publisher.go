// Package outbox publishes rows written by business transactions (§6.6).
// Every instance runs a publisher; a short lease keeps them off each other's
// rows, and a row is marked published only after Kafka acknowledged it.
// After a batch it wakes the services that consume what it sent
// (shared-messaging.md, "Scale to zero").
package outbox

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	kgo "github.com/segmentio/kafka-go"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const (
	batchSize = 100
	// publishLease outlives sendBudget, so a batch still being sent is never
	// leased to another pass.
	publishLease   = 2 * time.Minute
	sendBudget     = publishLease - 20*time.Second
	releaseTimeout = 5 * time.Second
)

// Sender is the part of kafka.Producer the publisher uses.
type Sender interface {
	Message(ctx context.Context, event, key, requestID string, data json.RawMessage) (kgo.Message, error)
	Write(ctx context.Context, msgs ...kgo.Message) error
}

type Publisher struct {
	DB       *repository.DB
	Producer Sender
	Interval time.Duration
	// Wake is called with each event a batch published.
	Wake    func(event string)
	healthy bool
}

func (p *Publisher) Healthy() bool { return p.healthy }

// Run publishes until ctx ends. Kafka being down leaves rows queued (§9.2).
func (p *Publisher) Run(ctx context.Context) {
	ticker := time.NewTicker(p.Interval)
	defer ticker.Stop()
	for {
		for {
			n, err := p.PublishBatch(ctx)
			p.healthy = err == nil
			if err != nil && ctx.Err() == nil {
				slog.Warn("outbox publish failed; will retry", "error", err)
			}
			if err != nil || n < batchSize {
				break
			}
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// PublishBatch leases, sends and marks one batch; Run calls it until the queue is empty.
func (p *Publisher) PublishBatch(ctx context.Context) (int, error) {
	// Lease, send and mark each hold the connection for one statement; the
	// storage and Kafka calls in between hold none.
	var rows []repository.OutboxRow
	if err := p.DB.AsSystem(ctx, func(tx pgx.Tx) (err error) {
		rows, err = repository.LeaseOutbox(ctx, tx, batchSize, publishLease)
		return err
	}); err != nil || len(rows) == 0 {
		return 0, err
	}
	ids, err := p.send(ctx, rows)
	if err != nil {
		p.release(ctx, rows)
		return 0, err
	}
	if err := p.DB.AsSystem(ctx, func(tx pgx.Tx) error { return repository.MarkPublished(ctx, tx, ids) }); err != nil {
		return 0, err
	}
	perEvent := map[string]int{}
	for _, row := range rows {
		perEvent[row.Event]++
	}
	for event, count := range perEvent {
		slog.Info("published to Kafka", "step", "outbox", "event", event, "topic", kafka.TopicFor[event], "messages", count)
		if p.Wake != nil {
			p.Wake(event)
		}
	}
	return len(rows), nil
}

// send builds and writes the leased rows within the lease and returns the ids
// to mark published. A crash before the mark re-sends after the lease; the
// consumers are idempotent by request_id (system-design.md §9.2).
func (p *Publisher) send(ctx context.Context, rows []repository.OutboxRow) ([]int64, error) {
	ctx, cancel := context.WithTimeout(ctx, sendBudget)
	defer cancel()
	msgs := make([]kgo.Message, 0, len(rows))
	ids := make([]int64, 0, len(rows))
	for _, row := range rows {
		msg, err := p.Producer.Message(ctx, row.Event, row.Key, row.RequestID, row.Payload)
		if errors.Is(err, kafka.ErrContract) {
			// A row that fails its schema can never be sent; park it
			// as published so it doesn't block the queue, and say so.
			slog.Error("outbox row violates the contract; skipped", "id", row.ID, "event", row.Event, "error", err)
			ids = append(ids, row.ID)
			continue
		} else if err != nil {
			// Storage for the claim-check is unavailable: retry the batch.
			return nil, err
		}
		msgs = append(msgs, msg)
		ids = append(ids, row.ID)
	}
	if len(msgs) > 0 {
		if err := p.Producer.Write(ctx, msgs...); err != nil {
			return nil, err
		}
	}
	return ids, nil
}

// release frees the lease of a batch that was not sent so the next pass
// retries it at once and in order; a failed release leaves the lease to lapse.
func (p *Publisher) release(ctx context.Context, rows []repository.OutboxRow) {
	ids := make([]int64, len(rows))
	for i, row := range rows {
		ids[i] = row.ID
	}
	ctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), releaseTimeout)
	defer cancel()
	if err := p.DB.AsSystem(ctx, func(tx pgx.Tx) error { return repository.ReleaseOutbox(ctx, tx, ids) }); err != nil {
		slog.Warn("outbox lease not released; it lapses on its own", "error", err)
	}
}
