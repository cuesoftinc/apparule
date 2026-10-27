package kafka

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

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
