package kafka

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	kgo "github.com/segmentio/kafka-go"

	"github.com/cuesoftinc/apparule/api/common/contract"
)

func example(t *testing.T, name string) []byte {
	raw, err := contract.Schemas.ReadFile("examples/" + name + ".json")
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func withVersion(t *testing.T, raw []byte, version string) []byte {
	var env map[string]any
	if err := json.Unmarshal(raw, &env); err != nil {
		t.Fatal(err)
	}
	env["version"] = version
	out, _ := json.Marshal(env)
	return out
}

type recorder struct {
	calls     int
	failures  int
	cause     error
	requestID string
}

func testConsumer(t *testing.T, r *recorder, failFor int) *Consumer {
	c, err := LoadContract()
	if err != nil {
		t.Fatal(err)
	}
	handle := func(ctx context.Context, _ json.RawMessage) error {
		r.calls++
		r.requestID = RequestID(ctx)
		if r.calls <= failFor {
			return errors.New("database away")
		}
		return nil
	}
	fail := func(_ context.Context, _ json.RawMessage, cause error) error {
		r.failures++
		r.cause = cause
		return nil
	}
	return &Consumer{topic: TopicResults, contract: c, attempts: 3, backoff: time.Millisecond,
		handlers: map[string]Handler{EventCaptureMeasured: handle},
		failures: map[string]Failure{EventCaptureMeasured: fail}}
}

func TestHandlerGetsTheRequestID(t *testing.T) {
	r := &recorder{}
	if !testConsumer(t, r, 0).process(context.Background(), 1, example(t, "capture.measured")) {
		t.Fatal("a handled message is committed")
	}
	if r.calls != 1 || r.requestID != "5c2a9d1e-3b4f-4a6c-8d7e-9f0a1b2c3d4e:1" || r.failures != 0 {
		t.Fatalf("got %+v", r)
	}
}

func TestAFailingHandlerIsRetriedThenRecordedAndCommitted(t *testing.T) {
	r := &recorder{}
	if !testConsumer(t, r, 100).process(context.Background(), 1, example(t, "capture.measured")) {
		t.Fatal("a message that keeps failing must be committed, never block the partition")
	}
	if r.calls != 3 || r.failures != 1 || r.cause == nil {
		t.Fatalf("want 3 attempts then one recorded failure, got %+v", r)
	}
}

func TestATransientFailureIsRetried(t *testing.T) {
	r := &recorder{}
	if !testConsumer(t, r, 1).process(context.Background(), 1, example(t, "capture.measured")) {
		t.Fatal("expected a commit")
	}
	if r.calls != 2 || r.failures != 0 {
		t.Fatalf("want a retry and no recorded failure, got %+v", r)
	}
}

func TestCancellationStopsWithoutCommitting(t *testing.T) {
	r := &recorder{}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if testConsumer(t, r, 100).process(ctx, 1, example(t, "capture.measured")) {
		t.Fatal("work cut short by shutdown must not be committed")
	}
	if r.failures != 0 {
		t.Fatalf("shutdown is not a failure: %+v", r)
	}
}

func TestAnUnsupportedMajorIsAContractErrorAndSkipped(t *testing.T) {
	r := &recorder{}
	c := testConsumer(t, r, 0)
	if _, err := c.unwrap(withVersion(t, example(t, "capture.measured"), "2.0")); !errors.Is(err, ErrContract) {
		t.Fatalf("want a contract error, got %v", err)
	}
	if !c.process(context.Background(), 1, withVersion(t, example(t, "capture.measured"), "2.0")) || r.calls != 0 {
		t.Fatalf("an unsupported major is committed unhandled: %+v", r)
	}
	if _, err := c.unwrap(withVersion(t, example(t, "capture.measured"), "1.7")); err != nil {
		t.Fatalf("a newer minor is accepted: %v", err)
	}
}

func TestOtherProductsMessagesAreSkipped(t *testing.T) {
	r := &recorder{}
	if !testConsumer(t, r, 0).process(context.Background(), 1, []byte(`{"type":"expendit.import.ready","version":"1.0"}`)) || r.calls != 0 {
		t.Fatalf("another product's message is committed unhandled: %+v", r)
	}
}

// queue is a reader with messages waiting: FetchMessage blocks on an empty
// queue until its context ends, as a reader on an idle topic does.
type queue struct {
	msgs      []kgo.Message
	committed []int64
}

func (q *queue) FetchMessage(ctx context.Context) (kgo.Message, error) {
	if len(q.msgs) == 0 {
		<-ctx.Done()
		return kgo.Message{}, ctx.Err()
	}
	m := q.msgs[0]
	q.msgs = q.msgs[1:]
	return m, nil
}

func (q *queue) CommitMessages(_ context.Context, msgs ...kgo.Message) error {
	for _, m := range msgs {
		q.committed = append(q.committed, m.Offset)
	}
	return nil
}

func (q *queue) Close() error { return nil }

func drainConsumer(t *testing.T, r *recorder, q *queue, caughtUp func(context.Context) (bool, error)) *Consumer {
	c := testConsumer(t, r, 0)
	c.reader, c.caughtUp, c.idle = q, caughtUp, 10*time.Millisecond
	return c
}

func TestDrainHandlesWhatIsWaitingThenReportsCaughtUp(t *testing.T) {
	r := &recorder{}
	raw := example(t, "capture.measured")
	q := &queue{msgs: []kgo.Message{{Offset: 7, Value: raw}, {Offset: 8, Value: raw}}}
	c := drainConsumer(t, r, q, func(context.Context) (bool, error) { return len(q.msgs) == 0, nil })

	ok, err := c.Drain(context.Background(), time.Minute)
	if err != nil || !ok {
		t.Fatalf("Drain = %v, %v; want caught up", ok, err)
	}
	if r.calls != 2 || len(q.committed) != 2 || q.committed[0] != 7 || q.committed[1] != 8 {
		t.Fatalf("handled %d, committed %v; want both messages handled and committed in order", r.calls, q.committed)
	}
}

func TestDrainStopsAtItsBudgetAndSaysItIsBehind(t *testing.T) {
	r := &recorder{}
	q := &queue{}
	c := drainConsumer(t, r, q, func(context.Context) (bool, error) { return false, nil })

	start := time.Now()
	ok, _ := c.Drain(context.Background(), 100*time.Millisecond)
	if ok {
		t.Fatal("Drain reported caught up with the group still behind")
	}
	if time.Since(start) > time.Second {
		t.Fatalf("Drain ran %s past a 100ms budget", time.Since(start))
	}
}

func TestDrainDoesNotCommitWhenItsRequestEndsMidMessage(t *testing.T) {
	r := &recorder{}
	q := &queue{msgs: []kgo.Message{{Offset: 3, Value: example(t, "capture.measured")}}}
	c := drainConsumer(t, r, q, func(context.Context) (bool, error) { return len(q.msgs) == 0, nil })
	c.handlers[EventCaptureMeasured] = func(context.Context, json.RawMessage) error { return errors.New("database away") }
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	if ok, _ := c.Drain(ctx, time.Minute); ok || len(q.committed) != 0 {
		t.Fatalf("caught up = %v, committed %v; want neither", ok, q.committed)
	}
}

func TestDrainWaitsForTheLoopWhileRunConsumes(t *testing.T) {
	r := &recorder{}
	q := &queue{msgs: []kgo.Message{{Offset: 1, Value: example(t, "capture.measured")}}}
	asked := 0
	c := drainConsumer(t, r, q, func(context.Context) (bool, error) { asked++; return asked > 1, nil })
	c.running.Store(true)

	ok, err := c.Drain(context.Background(), 5*time.Second)
	if err != nil || !ok {
		t.Fatalf("Drain = %v, %v", ok, err)
	}
	if r.calls != 0 || len(q.msgs) != 1 {
		t.Fatalf("Drain fetched while Run owns the reader: handled %d", r.calls)
	}
}
