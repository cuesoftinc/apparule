// Package sweep holds the scheduled jobs (system-design.md §6.7). Cloud
// Scheduler runs them as Cloud Run jobs from this image (cmd/jobs); all are
// lookup-then-write and safe to run twice.
package sweep

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
	"github.com/cuesoftinc/apparule/api/common/internal/wake"
)

type Sweeper struct {
	DB       *repository.DB
	Store    storage.Store
	Services *service.Services
	Now      func() time.Time
	// Wake and WakeURLs restart scaled-to-zero services while work is
	// pending (shared-messaging.md). Nil/empty: nothing to wake.
	Wake     *wake.Waker
	WakeURLs config.Wake
	Limits   config.Limits
}

// Jobs maps the cmd/jobs names to their functions.
func (s *Sweeper) Jobs() map[string]func(context.Context) error {
	return map[string]func(context.Context) error{
		"captures":  s.Captures,
		"orders":    s.Orders,
		"retention": s.Retention,
		"reconcile": s.Reconcile,
	}
}

// Captures runs every minute (§6.1 "Timeouts", X-11 re-send):
//   - awaiting_upload past its ticket's life -> deleted;
//   - processing past ProcessingResend -> capture.ready queued again, once;
//   - processing past ProcessingFail -> failed with pipeline_busy;
//
// then wakes common (to publish) and segmentation while work is pending.
func (s *Sweeper) Captures(ctx context.Context) error {
	var expired, resent, failed int64
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `DELETE FROM measurement_session s WHERE s.status = 'awaiting_upload'
			AND s.created_at < now() - interval '10 minutes'
			AND NOT EXISTS (SELECT 1 FROM upload_ticket t WHERE t.target_id = s.id AND t.used_at IS NULL AND t.expires_at > now())`)
		if err != nil {
			return err
		}
		expired = tag.RowsAffected()

		stuck, err := idList(ctx, tx, `SELECT id::text FROM measurement_session WHERE status = 'processing'
			AND resent_at IS NULL AND processing_since < now() - make_interval(secs => $1)`, s.Limits.ProcessingResend.Seconds())
		if err != nil {
			return err
		}
		for _, id := range stuck {
			if err := s.Services.ResendCapture(ctx, tx, id); err != nil {
				return err
			}
			resent++
		}

		tag, err = tx.Exec(ctx, `UPDATE measurement_session SET status = 'failed', error_code = 'pipeline_busy',
				processing_since = NULL
			WHERE status = 'processing' AND processing_since < now() - make_interval(secs => $1)`, s.Limits.ProcessingFail.Seconds())
		failed = tag.RowsAffected()
		return err
	})
	if err != nil {
		return err
	}
	slog.Info("captures swept", "step", "sweep", "expired", expired, "resent", resent, "failed", failed)
	s.wakePending(ctx)
	return nil
}

// Orders runs hourly: the clocks of order-lifecycle.md §1.
func (s *Sweeper) Orders(ctx context.Context) error {
	const day = 24 * time.Hour
	counts := map[string]int{}
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		run := func(status, clock string, age time.Duration, name string, fn func(id string) error) error {
			ids, err := repository.DueOrders(ctx, tx, status, clock, age)
			if err != nil {
				return err
			}
			for _, id := range ids {
				if err := fn(id); err != nil {
					var apiErr *service.Error
					if errors.As(err, &apiErr) {
						continue // the order moved since the lookup
					}
					return err
				}
				counts[name]++
			}
			return nil
		}
		if err := run("quoted", "quoted_at", 7*day, "quote_expired", func(id string) error { return s.Services.ExpireQuote(ctx, tx, id) }); err != nil {
			return err
		}
		if err := run("quoted", "quoted_at", 5*day, "quote_reminder", func(id string) error { return s.Services.Remind(ctx, tx, id, "quote_reminder") }); err != nil {
			return err
		}
		if err := run("paid", "paid", 14*day, "escrow_timeout", func(id string) error { return s.Services.EscrowTimeout(ctx, tx, id) }); err != nil {
			return err
		}
		if err := run("shipped", "shipped_at", 14*day, "auto_confirmed", func(id string) error { return s.Services.AutoConfirm(ctx, tx, id) }); err != nil {
			return err
		}
		if err := run("shipped", "shipped_at", 12*day, "reminder_12", func(id string) error { return s.Services.Remind(ctx, tx, id, "reminder_12") }); err != nil {
			return err
		}
		return run("shipped", "shipped_at", 7*day, "reminder_7", func(id string) error { return s.Services.Remind(ctx, tx, id, "reminder_7") })
	})
	if err != nil {
		return err
	}
	slog.Info("orders swept", "step", "sweep", "counts", counts)
	s.wakePending(ctx)
	return nil
}

// Retention runs daily (flows/vault.md §1, §3; data-model.md §6.4).
func (s *Sweeper) Retention(ctx context.Context) error {
	var keys []string
	counts := map[string]int64{}
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		// Unsaved results (24 h) and abandoned failures go with their images.
		k, err := idList(ctx, tx, `SELECT a.object_key FROM capture_asset a JOIN measurement_session s ON s.id = a.session_id
			WHERE s.status IN ('pending_save', 'failed_qc', 'failed') AND s.created_at < now() - interval '24 hours'`)
		if err != nil {
			return err
		}
		keys = append(keys, k...)
		tag, err := tx.Exec(ctx, `DELETE FROM measurement_session WHERE status IN ('pending_save', 'failed_qc', 'failed')
			AND created_at < now() - interval '24 hours'`)
		if err != nil {
			return err
		}
		counts["sessions"] = tag.RowsAffected()

		// Saved capture images past their 30 days; measurements stay.
		k, err = idList(ctx, tx, `DELETE FROM capture_asset WHERE retention_until < now() RETURNING object_key`)
		if err != nil {
			return err
		}
		keys = append(keys, k...)
		counts["capture_images"] = int64(len(k))

		// Unused uploads (composer batches never posted, attachments never sent).
		stale, err := repository.StaleMedia(ctx, tx, 24*time.Hour)
		if err != nil {
			return err
		}
		if len(stale) > 0 {
			k, err = idList(ctx, tx, `SELECT object_key FROM media WHERE batch_id::text = ANY($1)`, stale)
			if err != nil {
				return err
			}
			keys = append(keys, k...)
			if err := repository.DeleteMediaBatches(ctx, tx, stale); err != nil {
				return err
			}
		}
		for name, prune := range map[string]func() (int64, error){
			"threads":       func() (int64, error) { return repository.PruneThreads(ctx, tx, 30*24*time.Hour) },
			"notifications": func() (int64, error) { return repository.PruneNotifications(ctx, tx, 90*24*time.Hour) },
			"outbox":        func() (int64, error) { return repository.PruneOutbox(ctx, tx, 7*24*time.Hour) },
			"idempotency":   func() (int64, error) { return repository.PruneIdempotency(ctx, tx, 7*24*time.Hour) },
			"snapshots":     func() (int64, error) { return repository.PruneSnapshots(ctx, tx) },
			"tickets": func() (int64, error) {
				tag, err := tx.Exec(ctx, `DELETE FROM upload_ticket WHERE expires_at < now() - interval '1 day'`)
				return tag.RowsAffected(), err
			},
		} {
			n, err := prune()
			if err != nil {
				return fmt.Errorf("%s: %w", name, err)
			}
			counts[name] = n
		}
		// Accounts in deletion_pending with nothing in flight are purged
		// (flows/auth.md §4). Without order history the account and its
		// vault go entirely; with it, the vault and social data go and the
		// account row is anonymized, because the other party's orders still
		// reference it.
		settled := `a.deletion_state = 'deletion_pending' AND NOT EXISTS (SELECT 1 FROM request r
			WHERE (r.customer_account_id = a.id OR r.designer_account_id = a.id)
				AND r.status NOT IN ('delivered', 'refunded', 'declined', 'cancelled'))
			AND NOT EXISTS (SELECT 1 FROM payout p JOIN designer_profile d ON d.id = p.designer_id
				WHERE d.account_id = a.id AND p.state = 'pending')`
		hasOrders := `EXISTS (SELECT 1 FROM request r WHERE r.customer_account_id = a.id OR r.designer_account_id = a.id)`
		k, err = idList(ctx, tx, `SELECT ca.object_key FROM capture_asset ca JOIN measurement_session s ON s.id = ca.session_id
			JOIN customer c ON c.id = s.customer_id JOIN account a ON a.id = c.account_id WHERE `+settled)
		if err != nil {
			return err
		}
		keys = append(keys, k...)
		tag, err = tx.Exec(ctx, `DELETE FROM account a WHERE `+settled+` AND NOT `+hasOrders)
		if err != nil {
			return err
		}
		counts["accounts_deleted"] = tag.RowsAffected()
		if _, err := tx.Exec(ctx, `DELETE FROM measurement_session s USING customer c, account a
			WHERE c.id = s.customer_id AND a.id = c.account_id AND `+settled); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, `DELETE FROM post p USING designer_profile d, account a
			WHERE d.id = p.designer_id AND a.id = d.account_id AND `+settled); err != nil {
			return err
		}
		tag, err = tx.Exec(ctx, `UPDATE account a SET email = 'deleted+' || a.id || '@invalid', firebase_uid = 'deleted:' || a.id,
				username = 'deleted_' || substr(replace(a.id::text, '-', ''), 1, 12), display_name = 'Deleted user',
				avatar_url = NULL, profile_location = NULL, deletion_state = 'active', suspended_at = coalesce(suspended_at, now())
			WHERE `+settled+` AND `+hasOrders)
		if err != nil {
			return err
		}
		counts["accounts_anonymized"] = tag.RowsAffected()
		return nil
	})
	if err != nil {
		return err
	}
	for _, k := range keys {
		if err := s.Store.Delete(ctx, k); err != nil {
			slog.Warn("object delete failed; next run retries", "error", err)
		}
	}
	// Claim-check payloads and leftover tmp/ objects older than a day (the
	// bucket lifecycle does this in cloud; compose has no lifecycle rule).
	cutoff := s.Now().Add(-24 * time.Hour)
	for _, prefix := range []string{storage.ComputePrefix(s.Store), storage.TmpPrefix(s.Store)} {
		objects, err := s.Store.List(ctx, prefix)
		if err != nil {
			slog.Warn("listing for cleanup failed", "prefix", strings.TrimPrefix(prefix, s.Store.Prefix()), "error", err)
			continue
		}
		for _, o := range objects {
			if o.Created.Before(cutoff) {
				_ = s.Store.Delete(ctx, o.Key)
				counts["objects"]++
			}
		}
	}
	slog.Info("retention swept", "step", "sweep", "counts", counts)
	return nil
}

// Reconcile runs hourly: it hands commerce the last window's movements to
// compare with Paystack (§6.4).
func (s *Sweeper) Reconcile(ctx context.Context) error {
	to := s.Now().UTC().Truncate(time.Hour)
	from := to.Add(-time.Hour)
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		movements, err := repository.Movements(ctx, tx, from, to)
		if err != nil {
			return err
		}
		if movements == nil {
			movements = []repository.Movement{}
		}
		return repository.Enqueue(ctx, tx, kafka.EventLedgerReconcile, "reconcile", map[string]any{
			"window":    map[string]string{"from": from.Format(time.RFC3339), "to": to.Format(time.RFC3339)},
			"movements": movements,
		})
	})
	if err != nil {
		return err
	}
	s.wakePending(ctx)
	return nil
}

// wakePending wakes common while its outbox holds rows (its publisher sends
// them), and the consumers that have work queued or in flight.
func (s *Sweeper) wakePending(ctx context.Context) {
	if s.Wake == nil {
		return
	}
	var pending map[string]int
	var processing int
	if err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		var err error
		if pending, err = repository.PendingOutbox(ctx, tx); err != nil {
			return err
		}
		return tx.QueryRow(ctx, `SELECT count(*) FROM measurement_session WHERE status = 'processing'`).Scan(&processing)
	}); err != nil {
		slog.Warn("pending-work lookup failed", "error", err)
		return
	}
	if len(pending) > 0 {
		_ = s.Wake.Now(ctx, s.WakeURLs.Common, "outbox")
	}
	if processing > 0 || pending[kafka.EventCaptureReady] > 0 {
		_ = s.Wake.Now(ctx, s.WakeURLs.Segmentation, "captures")
	}
	for event := range pending {
		if kafka.TopicFor[event] == kafka.TopicRequests && event != kafka.EventCaptureReady {
			_ = s.Wake.Now(ctx, s.WakeURLs.Commerce, event)
			break
		}
	}
}

func idList(ctx context.Context, tx pgx.Tx, sql string, args ...any) ([]string, error) {
	rows, err := tx.Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, rows.Err()
}
