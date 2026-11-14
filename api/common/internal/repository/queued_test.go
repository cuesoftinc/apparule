package repository

import (
	"context"
	"testing"
)

func TestQueuedCountsRowsQueuedUnderItsContext(t *testing.T) {
	ctx, q := WithQueued(context.Background())
	if q.Any() {
		t.Fatal("a request that queued nothing must not report rows")
	}
	NoteQueued(ctx)
	if !q.Any() {
		t.Fatal("a queued row must be visible to the request's flush")
	}
}

func TestNoteQueuedWithoutARequestDoesNothing(t *testing.T) {
	NoteQueued(context.Background()) // consumers and sweeps have no request to flush for
}
