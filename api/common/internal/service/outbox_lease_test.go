package service_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	kgo "github.com/segmentio/kafka-go"

	"github.com/cuesoftinc/apparule/api/common/internal/outbox"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// sender is an outbox.Sender that fails the test when it is called while the
// publisher holds a pooled connection.
type sender struct {
	e     *env
	t     *testing.T
	sent  []string
	fail  error
	calls int
}

func (s *sender) Message(_ context.Context, event, key, requestID string, data json.RawMessage) (kgo.Message, error) {
	s.held("message")
	return kgo.Message{Topic: event, Key: []byte(key), Value: data}, nil
}

func (s *sender) Write(_ context.Context, msgs ...kgo.Message) error {
	s.held("write")
	s.calls++
	if s.fail != nil {
		return s.fail
	}
	for _, m := range msgs {
		s.sent = append(s.sent, string(m.Key))
	}
	return nil
}

func (s *sender) held(op string) {
	if n := s.e.db.Pool.Stat().AcquiredConns(); n != 0 {
		s.t.Errorf("outbox %s while %d pooled connection(s) are held", op, n)
	}
}

func (e *env) enqueue(t *testing.T, keys ...string) {
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		for _, k := range keys {
			if err := repository.Enqueue(ctx, tx, "test.event", k, map[string]string{"k": k}); err != nil {
				return err
			}
		}
		return nil
	})
}

func (e *env) unsent(t *testing.T) int {
	var n int
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT count(*) FROM outbox WHERE published_at IS NULL`).Scan(&n)
	})
	return n
}

func TestOutboxPublishHoldsNoConnection(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	snd := &sender{e: e, t: t}
	woke := 0
	pub := &outbox.Publisher{DB: e.db, Producer: snd, Interval: time.Hour, Wake: func(context.Context, []string) { woke++ }}

	e.enqueue(t, "a", "b", "c")
	n, err := pub.Flush(ctx)
	if err != nil || n != 3 || len(snd.sent) != 3 || woke != 1 {
		t.Fatalf("publish: n=%d err=%v sent=%v woke=%d", n, err, snd.sent, woke)
	}
	if got := e.unsent(t); got != 0 {
		t.Fatalf("%d rows left unsent after a successful batch", got)
	}
	if n, err := pub.PublishBatch(ctx); err != nil || n != 0 {
		t.Fatalf("empty queue: n=%d err=%v", n, err)
	}
}

func TestOutboxFailedSendKeepsRowsAndOrder(t *testing.T) {
	e := setup(t)
	ctx := context.Background()
	snd := &sender{e: e, t: t, fail: errors.New("kafka down")}
	pub := &outbox.Publisher{DB: e.db, Producer: snd, Interval: time.Hour}

	e.enqueue(t, "a", "b", "c")
	if n, err := pub.PublishBatch(ctx); err == nil || n != 0 {
		t.Fatalf("a failed send must report the error: n=%d err=%v", n, err)
	}
	if got := e.unsent(t); got != 3 {
		t.Fatalf("a failed send lost rows: %d unsent, want 3", got)
	}
	// The lease was released, so the next pass retries at once, in order.
	snd.fail = nil
	n, err := pub.PublishBatch(ctx)
	if err != nil || n != 3 || len(snd.sent) != 3 || snd.sent[0] != "a" || snd.sent[1] != "b" || snd.sent[2] != "c" {
		t.Fatalf("retry: n=%d err=%v sent=%v", n, err, snd.sent)
	}
	if got := e.unsent(t); got != 0 {
		t.Fatalf("%d rows left unsent after the retry", got)
	}
}

func TestOutboxLeaseSkipsLeasedAndRetakesLapsed(t *testing.T) {
	e := setup(t)
	e.enqueue(t, "a", "b")
	lease := func(d time.Duration) []repository.OutboxRow {
		var rows []repository.OutboxRow
		e.system(t, func(ctx context.Context, tx pgx.Tx) (err error) {
			rows, err = repository.LeaseOutbox(ctx, tx, 10, d, "a")
			return err
		})
		return rows
	}
	first := lease(time.Hour)
	if len(first) != 2 || first[0].Key != "a" || first[1].Key != "b" {
		t.Fatalf("first lease: %+v", first)
	}
	if again := lease(time.Hour); len(again) != 0 {
		t.Fatalf("a leased row was leased twice: %+v", again)
	}
	// A crashed publisher's lease lapses and the rows come back, unsent.
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE outbox SET lease_until = now() - interval '1 second'`)
		return err
	})
	if retaken := lease(time.Hour); len(retaken) != 2 {
		t.Fatalf("lapsed lease not retaken: %+v", retaken)
	}
}

// A pass whose lease lapsed cannot free or mark rows another pass leased since.
func TestOutboxOwnerTokenGuardsReleaseAndMark(t *testing.T) {
	e := setup(t)
	e.enqueue(t, "a")
	lease := func(owner string) []repository.OutboxRow {
		var rows []repository.OutboxRow
		e.system(t, func(ctx context.Context, tx pgx.Tx) (err error) {
			rows, err = repository.LeaseOutbox(ctx, tx, 10, time.Hour, owner)
			return err
		})
		return rows
	}
	first := lease("old")
	if len(first) != 1 {
		t.Fatalf("lease: %+v", first)
	}
	// The old pass stalls; its lease lapses and a new pass takes the row.
	e.system(t, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE outbox SET lease_until = now() - interval '1 second'`)
		return err
	})
	if got := lease("new"); len(got) != 1 {
		t.Fatalf("new pass lease: %+v", got)
	}
	ids := []int64{first[0].ID}
	e.system(t, func(ctx context.Context, tx pgx.Tx) error { return repository.ReleaseOutbox(ctx, tx, ids, "old") })
	if again := lease("third"); len(again) != 0 {
		t.Fatalf("a late release freed another pass's lease: %+v", again)
	}
	e.system(t, func(ctx context.Context, tx pgx.Tx) error { return repository.MarkPublished(ctx, tx, ids, "old") })
	if got := e.unsent(t); got != 1 {
		t.Fatalf("a late mark published another pass's row: %d unsent", got)
	}
	e.system(t, func(ctx context.Context, tx pgx.Tx) error { return repository.MarkPublished(ctx, tx, ids, "new") })
	if got := e.unsent(t); got != 0 {
		t.Fatalf("the owner's mark did not publish: %d unsent", got)
	}
}
