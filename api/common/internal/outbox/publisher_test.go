package outbox

import (
	"context"
	"errors"
	"reflect"
	"testing"
)

type batch struct {
	n   int
	per map[string]int
	err error
}

func batches(bs ...batch) batchFunc {
	return func(context.Context) (int, map[string]int, error) {
		if len(bs) == 0 {
			return 0, nil, nil
		}
		b := bs[0]
		bs = bs[1:]
		return b.n, b.per, b.err
	}
}

func TestFlushPublishesUntilTheOutboxIsEmptyThenWakesOnce(t *testing.T) {
	var woken [][]string
	n, err := flush(context.Background(), batches(
		batch{n: batchSize, per: map[string]int{"apparule.capture.ready": batchSize}},
		batch{n: 3, per: map[string]int{"apparule.capture.ready": 1, "apparule.orders.transition": 2}},
	), func(_ context.Context, events []string) { woken = append(woken, events) })
	if err != nil || n != batchSize+3 {
		t.Fatalf("flush = %d, %v; want %d rows", n, err, batchSize+3)
	}
	want := [][]string{{"apparule.capture.ready", "apparule.orders.transition"}}
	if !reflect.DeepEqual(woken, want) {
		t.Fatalf("woken = %v; want one wake naming each event once: %v", woken, want)
	}
}

func TestFlushWakesNobodyWhenNothingWasSent(t *testing.T) {
	woke := false
	n, err := flush(context.Background(), batches(), func(context.Context, []string) { woke = true })
	if err != nil || n != 0 || woke {
		t.Fatalf("flush = %d, %v, woke %v; want an idle flush to wake nobody", n, err, woke)
	}
}

func TestFlushStillWakesForWhatWasSentBeforeAFailure(t *testing.T) {
	var woken []string
	boom := errors.New("kafka away")
	n, err := flush(context.Background(), batches(
		batch{n: batchSize, per: map[string]int{"apparule.capture.ready": batchSize}},
		batch{err: boom},
	), func(_ context.Context, events []string) { woken = events })
	if !errors.Is(err, boom) || n != batchSize {
		t.Fatalf("flush = %d, %v; want the first batch counted and the error returned", n, err)
	}
	if !reflect.DeepEqual(woken, []string{"apparule.capture.ready"}) {
		t.Fatalf("woken = %v; want the consumers of the first batch settled", woken)
	}
}
