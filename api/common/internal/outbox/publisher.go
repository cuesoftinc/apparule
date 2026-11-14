// Package outbox publishes rows written by business transactions (§6.6).
// Every instance can publish; a short lease keeps them off each other's rows,
// and a row is marked published only after Kafka acknowledged it. Where CPU
// is always allocated the publisher runs in a loop (Run); on request-based
// CPU (S-14) the server calls Flush inside the request or settle that needs
// the rows sent, and Flush then settles the services that consume what it
// sent (shared-messaging.md, "Scale to zero").
package outbox

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	kgo "github.com/segmentio/kafka-go"

	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

const (
	batchSize = 100
	// publishLease outlives sendBudget, so a batch still being sent is never
	// leased to another pass.
	publishLease   = time.Minute
	sendBudget     = publishLease - 20*time.Second
	releaseTimeout = 5 * time.Second
	markAttempts   = 3
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

// PublishBatch leases, sends and marks one batch without settling consumers.
func (p *Publisher) PublishBatch(ctx context.Context) (int, error) {
	n, _, err := p.publishBatch(ctx)
	return n, err
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
	// Lease, send and mark each hold the connection for one statement; the
	// storage and Kafka calls in between hold none, and the wake runs after
	// all three, so no transaction spans an outside call.
	// The owner token keeps a pass whose lease lapsed from freeing or marking
	// rows another pass has leased since.
	owner := uuid.NewString()
	var rows []repository.OutboxRow
	if err := p.DB.AsSystem(ctx, func(tx pgx.Tx) (err error) {
		rows, err = repository.LeaseOutbox(ctx, tx, batchSize, publishLease, owner)
		return err
	}); err != nil || len(rows) == 0 {
		return 0, nil, err
	}
	ids, err := p.send(ctx, rows)
	if err != nil {
		p.release(ctx, rows, owner)
		return 0, nil, err
	}
	if err := p.mark(ctx, ids, owner); err != nil {
		return 0, nil, err
	}
	perEvent := map[string]int{}
	for _, row := range rows {
		perEvent[row.Event]++
	}
	for event, count := range perEvent {
		slog.Info("published to Kafka", "step", "outbox", "event", event, "topic", kafka.TopicFor[event], "messages", count)
	}
	return len(rows), perEvent, nil
}

// mark records the sent rows, retrying at once: a mark that fails would leave
// sent rows leased until the lease lapses and then send them again. The mark
// does not stop when ctx does, or a sent batch would go out twice.
func (p *Publisher) mark(ctx context.Context, ids []int64, owner string) (err error) {
	for attempt := 0; attempt < markAttempts; attempt++ {
		if attempt > 0 {
			time.Sleep(time.Duration(attempt) * 250 * time.Millisecond)
		}
		mctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), releaseTimeout)
		err = p.DB.AsSystem(mctx, func(tx pgx.Tx) error { return repository.MarkPublished(mctx, tx, ids, owner) })
		cancel()
		if err == nil {
			return nil
		}
		slog.Warn("outbox mark failed; retrying", "attempt", attempt+1, "error", err)
	}
	return err
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
func (p *Publisher) release(ctx context.Context, rows []repository.OutboxRow, owner string) {
	ids := make([]int64, len(rows))
	for i, row := range rows {
		ids[i] = row.ID
	}
	ctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), releaseTimeout)
	defer cancel()
	if err := p.DB.AsSystem(ctx, func(tx pgx.Tx) error { return repository.ReleaseOutbox(ctx, tx, ids, owner) }); err != nil {
		slog.Warn("outbox lease not released; it lapses on its own", "error", err)
	}
}
