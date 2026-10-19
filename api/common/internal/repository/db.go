// Package repository is the only code that talks to Postgres (S-3: api/common
// is its sole client). Every statement runs inside a transaction that is
// either scoped to one account, so row-level security keeps the vault,
// orders and notifications to their owners (S-11), or explicitly marked as a
// system operation (sign-in, consumers, sweeps, moderation).
package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound is returned for missing rows, including rows that belong to
// someone else (cross-account access is not_found, never forbidden:
// engineering.md §2).
var ErrNotFound = errors.New("not found")

// ErrConflict is returned for unique-constraint violations.
var ErrConflict = errors.New("conflict")

type DB struct {
	Pool *pgxpool.Pool
}

func Open(ctx context.Context, url string) (*DB, error) {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		return nil, err
	}
	return &DB{Pool: pool}, nil
}

func (db *DB) Close() { db.Pool.Close() }

func (db *DB) Ping(ctx context.Context) error { return db.Pool.Ping(ctx) }

// AsAccount runs fn in a transaction where row-level security sees only
// accountID's private rows (its vault, its orders, its notifications).
// Public social tables (posts, follows, comments) have no policies.
func (db *DB) AsAccount(ctx context.Context, accountID string, fn func(pgx.Tx) error) error {
	return pgx.BeginFunc(ctx, db.Pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `SELECT set_config('app.account_id', $1, true)`, accountID); err != nil {
			return err
		}
		return fn(tx)
	})
}

// AsSystem runs fn with row-level security bypassed: sign-in, consumers,
// sweeps, webhooks and staff moderation.
func (db *DB) AsSystem(ctx context.Context, fn func(pgx.Tx) error) error {
	return pgx.BeginFunc(ctx, db.Pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `SELECT set_config('app.bypass_rls', 'on', true)`); err != nil {
			return err
		}
		return fn(tx)
	})
}

// translate maps driver errors onto the package's sentinel errors.
func translate(err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrNotFound
	}
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return ErrConflict
	}
	return err
}
