// Package outbox publishes rows written by business transactions (§6.6).
// Every instance can publish; SKIP LOCKED keeps them off each other's rows,
// and a row is marked published only after Kafka acknowledged it. Where CPU
// is always allocated the publisher runs in a loop (Run); on request-based
// CPU (S-14) the server calls Flush inside the request or settle that needs
// the rows sent, and Flush then settles the services that consume what it
// sent (shared-messaging.md, "Scale to zero").
package outbox

import (
	"context"
	"errors"
	"log/slog"
	"sort"
	"time"

	"github.com/jackc/pgx/v5"
	kgo "github.com/segmentio/kafka-go"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const batchSize = 100

type Publisher struct {
	DB       *repository.DB
	Producer *kafka.Producer
	Interval time.Duration
	// Wake is called after a flush with the events it published, and returns
	// once the services that consume them have answered.
	Wake    func(ctx context.Context, events []string)
	healthy bool
}

func (p *Publisher) Healthy() bool { return p.healthy }

// Run flushes every Interval until ctx ends. Kafka being down leaves rows
// queued (§9.2). Only where CPU is always allocated.
func (p *Publisher) Run(ctx context.Context) {
	ticker := time.NewTicker(p.Interval)
	defer ticker.Stop()
	for {
		_, err := p.Flush(ctx)
		p.healthy = err == nil
		if err != nil && ctx.Err() == nil {
			slog.Warn("outbox publish failed; will retry", "error", err)
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// Flush publishes batches until the outbox is empty, then settles the
// consumers of what it sent, and returns how many rows it sent. A failure
// leaves the rest for the next flush.
func (p *Publisher) Flush(ctx context.Context) (int, error) {
	return flush(ctx, p.publishBatch, p.Wake)
}

// batchFunc publishes one batch: the rows it claimed and, per event, how
// many it sent.
type batchFunc func(ctx context.Context) (int, map[string]int, error)

func flush(ctx context.Context, batch batchFunc, wake func(context.Context, []string)) (int, error) {
	sent := map[string]int{}
	total := 0
	var err error
	for {
		var n int
		var per map[string]int
		n, per, err = batch(ctx)
		total += n
		for event, count := range per {
			sent[event] += count
		}
		if err != nil || n < batchSize {
			break
		}
	}
	if wake != nil && len(sent) > 0 {
		events := make([]string, 0, len(sent))
		for event := range sent {
			events = append(events, event)
		}
		sort.Strings(events)
		wake(ctx, events)
	}
	return total, err
}

func (p *Publisher) publishBatch(ctx context.Context) (int, map[string]int, error) {
	var n int
	perEvent := map[string]int{}
	err := p.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		rows, err := repository.ClaimOutbox(ctx, tx, batchSize)
		if err != nil || len(rows) == 0 {
			return err
		}
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
				return err
			}
			msgs = append(msgs, msg)
			ids = append(ids, row.ID)
		}
		if err := p.Producer.Write(ctx, msgs...); err != nil {
			return err
		}
		n = len(rows)
		if err := repository.MarkPublished(ctx, tx, ids); err != nil {
			return err
		}
		for _, row := range rows {
			perEvent[row.Event]++
		}
		for event, count := range perEvent {
			slog.Info("published to Kafka", "step", "outbox", "event", event, "topic", kafka.TopicFor[event], "messages", count)
		}
		return nil
	})
	if err != nil {
		return 0, nil, err
	}
	return n, perEvent, nil
}
