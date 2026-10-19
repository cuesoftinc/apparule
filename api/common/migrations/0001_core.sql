-- Core schema: data-model.md §2, §5, §6 as Postgres (S-3), plus
-- system-design.md §5.2 (capture status, upload tickets, provider events,
-- the ledger, the outbox).
--
-- Tenancy (S-11): the app sets app.account_id per transaction; consumers,
-- sweeps and staff set app.bypass_rls. Private rows (the vault, orders and
-- their threads, notifications, consent) have FORCE row-level security.
-- Public social rows (designer profiles, posts, comments, follows) have
-- none: anyone may read them, and api/common checks every write.
-- System tables (tickets, idempotency, provider events, ledger, outbox) are
-- visible only with the bypass.

CREATE FUNCTION app_bypass() RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT coalesce(current_setting('app.bypass_rls', true), '') = 'on'
$$;

CREATE FUNCTION app_account() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT nullif(current_setting('app.account_id', true), '')::uuid
$$;

CREATE FUNCTION app_account_visible(row_account uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT app_bypass() OR row_account = app_account()
$$;

-- ── Accounts (X-1: Firebase, Google only) ───────────────────────────────

CREATE TABLE account (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid          text NOT NULL UNIQUE,
  email                 text NOT NULL,
  username              text NOT NULL CHECK (username ~ '^[a-z0-9._]{3,30}$'),
  username_changed_at   timestamptz,
  display_name          text NOT NULL DEFAULT '',
  avatar_url            text,
  -- Self-attested {city, state, country} (X-10 tier 1). Sensitive PII.
  profile_location      jsonb,
  deletion_state        text NOT NULL DEFAULT 'active' CHECK (deletion_state IN ('active', 'deletion_pending')),
  deletion_requested_at timestamptz,
  is_staff              boolean NOT NULL DEFAULT false,
  suspended_at          timestamptz,
  notification_prefs    jsonb NOT NULL DEFAULT '{"quotes":true,"order_status":true,"social":true,"payouts":true}',
  created_at            timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX account_username ON account (lower(username));

CREATE TABLE consent_record (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  document     text NOT NULL CHECK (document IN ('tos', 'privacy')),
  version      text NOT NULL,
  accepted_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX consent_record_account ON consent_record (account_id, document, accepted_at DESC);
ALTER TABLE consent_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_record FORCE ROW LEVEL SECURITY;
CREATE POLICY consent_owner ON consent_record USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

CREATE TABLE device_token (
  token       text PRIMARY KEY,
  account_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  platform    text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX device_token_account ON device_token (account_id);
ALTER TABLE device_token ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_token FORCE ROW LEVEL SECURITY;
CREATE POLICY device_owner ON device_token USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

-- ── Workspaces and customers (data-model.md §2, §6.1) ───────────────────

CREATE TABLE workspace (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  plan        text NOT NULL DEFAULT 'cloud' CHECK (plan IN ('oss', 'cloud')),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE workspace_member (
  workspace_id  uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  account_id    uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  role          text NOT NULL CHECK (role IN ('owner', 'member')),
  PRIMARY KEY (workspace_id, account_id)
);
ALTER TABLE workspace_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_member FORCE ROW LEVEL SECURITY;
CREATE POLICY member_self ON workspace_member USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

-- A workspace's rows are visible to its members (the policy's subquery runs
-- under workspace_member's own policy, so it only sees the caller's rows).
CREATE FUNCTION app_workspace_visible(row_workspace uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT app_bypass() OR EXISTS (
    SELECT 1 FROM workspace_member m WHERE m.workspace_id = row_workspace AND m.account_id = app_account())
$$;

ALTER TABLE workspace ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace FORCE ROW LEVEL SECURITY;
CREATE POLICY workspace_members ON workspace USING (app_workspace_visible(id)) WITH CHECK (app_workspace_visible(id));

CREATE TABLE customer (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id          uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  -- Set for kind = self: the account whose personal vault this is.
  account_id            uuid REFERENCES account (id) ON DELETE CASCADE,
  kind                  text NOT NULL CHECK (kind IN ('self', 'client')),
  display_name          text NOT NULL DEFAULT '',
  contact               text,
  notes                 text NOT NULL DEFAULT '',
  -- A-10 measurement template; null until chosen, never cleared.
  measurement_template  text CHECK (measurement_template IN ('women', 'men')),
  created_at            timestamptz NOT NULL DEFAULT now(),
  deleted_at            timestamptz,
  CHECK ((kind = 'self') = (account_id IS NOT NULL))
);
CREATE UNIQUE INDEX customer_one_self ON customer (account_id) WHERE kind = 'self';
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer FORCE ROW LEVEL SECURITY;
CREATE POLICY customer_workspace ON customer USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

CREATE TABLE instance_request (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  account_id    uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  status        text NOT NULL DEFAULT 'queued'
                CHECK (status IN ('queued', 'provisioning', 'active', 'rejected', 'cancelled', 'deprovisioned')),
  notes         text NOT NULL DEFAULT '',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE instance_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE instance_request FORCE ROW LEVEL SECURITY;
CREATE POLICY instance_request_workspace ON instance_request USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

-- ── The vault: sessions, measurements, capture images (§6.1, §6.2) ──────

CREATE TABLE measurement_session (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id      uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  customer_id       uuid NOT NULL REFERENCES customer (id) ON DELETE CASCADE,
  method            text NOT NULL CHECK (method IN ('mediapipe_2d', 'mediapipe_2d_v2', 'smpl_v1', 'manual')),
  -- Null for manual sessions (data-model.md §2).
  input_height_cm   numeric(5, 1) CHECK (input_height_cm BETWEEN 100 AND 230),
  status            text NOT NULL CHECK (status IN
                    ('awaiting_upload', 'processing', 'failed_qc', 'pending_save', 'complete', 'failed')),
  -- The template the capture was measured against (A-10b).
  template          text CHECK (template IN ('women', 'men')),
  qc_code           text,
  qc_pose           text CHECK (qc_pose IN ('front', 'side')),
  error_code        text,
  -- Grows with each upload (first and retakes); segmentation echoes it.
  attempt           integer NOT NULL DEFAULT 0,
  pipeline_meta     jsonb NOT NULL DEFAULT '{}',
  idempotency_key   text,
  processing_since  timestamptz,
  -- When capture.ready was queued again by the sweep (X-11: re-send once).
  resent_at         timestamptz,
  saved_at          timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX measurement_session_customer ON measurement_session (customer_id, created_at DESC);
CREATE INDEX measurement_session_status ON measurement_session (status) WHERE status IN ('awaiting_upload', 'processing', 'pending_save');
CREATE UNIQUE INDEX measurement_session_idempotency ON measurement_session (customer_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
ALTER TABLE measurement_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement_session FORCE ROW LEVEL SECURITY;
CREATE POLICY session_workspace ON measurement_session USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

CREATE TABLE measurement (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    uuid NOT NULL REFERENCES measurement_session (id) ON DELETE CASCADE,
  workspace_id  uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  position      integer NOT NULL,
  name          text NOT NULL CHECK (name ~ '^[a-z][a-z0-9_]*$'),
  value_cm      numeric(6, 1) NOT NULL CHECK (value_cm > 0),
  source        text NOT NULL CHECK (source IN ('pipeline', 'manual_correction')),
  confidence    numeric(3, 2) CHECK (confidence BETWEEN 0 AND 1),
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX measurement_session_order ON measurement (session_id, position);
ALTER TABLE measurement ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurement FORCE ROW LEVEL SECURITY;
CREATE POLICY measurement_workspace ON measurement USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

CREATE TABLE capture_asset (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id       uuid NOT NULL REFERENCES measurement_session (id) ON DELETE CASCADE,
  workspace_id     uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  pose             text NOT NULL CHECK (pose IN ('front', 'side')),
  object_key       text NOT NULL,
  width            integer NOT NULL,
  height           integer NOT NULL,
  size_bytes       bigint NOT NULL DEFAULT 0,
  -- tmp: in tmp/ until saved; confirmed: moved to captures/ on save.
  stage            text NOT NULL DEFAULT 'tmp' CHECK (stage IN ('tmp', 'confirmed')),
  -- The QC verdict from the latest attempt that reached this pose.
  accepted         boolean,
  retention_until  timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (session_id, pose)
);
CREATE INDEX capture_asset_retention ON capture_asset (retention_until) WHERE retention_until IS NOT NULL;
ALTER TABLE capture_asset ENABLE ROW LEVEL SECURITY;
ALTER TABLE capture_asset FORCE ROW LEVEL SECURITY;
CREATE POLICY capture_asset_workspace ON capture_asset USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

CREATE TABLE session_export (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    uuid NOT NULL REFERENCES measurement_session (id) ON DELETE CASCADE,
  workspace_id  uuid NOT NULL REFERENCES workspace (id) ON DELETE CASCADE,
  format        text NOT NULL CHECK (format IN ('pdf', 'csv')),
  object_key    text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE session_export ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_export FORCE ROW LEVEL SECURITY;
CREATE POLICY export_workspace ON session_export USING (app_workspace_visible(workspace_id)) WITH CHECK (app_workspace_visible(workspace_id));

-- ── Upload tickets (S-15) and uploaded media ────────────────────────────

CREATE TABLE upload_ticket (
  jti          uuid PRIMARY KEY,
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  target_kind  text NOT NULL CHECK (target_kind IN ('capture', 'post_media', 'attachment')),
  target_id    uuid NOT NULL,
  poses        text[] NOT NULL DEFAULT '{}',
  max_files    integer NOT NULL,
  max_bytes    bigint NOT NULL,
  expires_at   timestamptz NOT NULL,
  used_at      timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX upload_ticket_target ON upload_ticket (target_id);
ALTER TABLE upload_ticket ENABLE ROW LEVEL SECURITY;
ALTER TABLE upload_ticket FORCE ROW LEVEL SECURITY;
CREATE POLICY upload_ticket_system ON upload_ticket USING (app_bypass()) WITH CHECK (app_bypass());

-- A batch of post media (a designer's composer upload) or one thread
-- attachment, waiting for or holding its images.
CREATE TABLE media_batch (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('post_media', 'attachment')),
  request_id   uuid,
  status       text NOT NULL DEFAULT 'awaiting_upload' CHECK (status IN ('awaiting_upload', 'ready')),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE media (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id     uuid NOT NULL REFERENCES media_batch (id) ON DELETE CASCADE,
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('post_media', 'attachment')),
  position     integer NOT NULL,
  object_key   text NOT NULL,
  width        integer NOT NULL,
  height       integer NOT NULL,
  size_bytes   bigint NOT NULL DEFAULT 0,
  -- tmp until used by a post or a message, then moved (§6.2).
  stage        text NOT NULL DEFAULT 'tmp' CHECK (stage IN ('tmp', 'confirmed')),
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX media_batch_order ON media (batch_id, position);

-- ── Designers and the social graph (§5, §6.5) ───────────────────────────

CREATE TABLE designer_profile (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id        uuid NOT NULL UNIQUE REFERENCES account (id) ON DELETE CASCADE,
  display_name      text NOT NULL,
  bio               text NOT NULL DEFAULT '',
  verified          boolean NOT NULL DEFAULT false,
  -- Payout account (pages.md B8, A-2): Paystack transfer recipient + KYC.
  kyc_state         text NOT NULL DEFAULT 'none' CHECK (kyc_state IN ('none', 'pending', 'verified', 'lapsed')),
  kyc_reason        text,
  recipient_code    text,
  bank_code         text,
  bank_name         text,
  account_last4     text,
  account_name      text,
  -- The attempt common is waiting on; outcomes for older attempts are ignored.
  payout_attempt_id uuid,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE follow (
  follower_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  designer_id  uuid NOT NULL REFERENCES designer_profile (id) ON DELETE CASCADE,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, designer_id)
);
CREATE INDEX follow_designer ON follow (designer_id);

CREATE TABLE post (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  designer_id       uuid NOT NULL REFERENCES designer_profile (id) ON DELETE CASCADE,
  caption           text NOT NULL CHECK (char_length(caption) BETWEEN 1 AND 500),
  style_tags        text[] NOT NULL DEFAULT '{}',
  base_price_cents  bigint CHECK (base_price_cents > 0),
  currency          char(3) NOT NULL DEFAULT 'NGN',
  turnaround_days   integer NOT NULL CHECK (turnaround_days BETWEEN 1 AND 365),
  -- Updated in the same transaction as the like or comment (§5.2).
  like_count        integer NOT NULL DEFAULT 0 CHECK (like_count >= 0),
  comment_count     integer NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
  hidden_at         timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX post_designer ON post (designer_id, created_at DESC);
CREATE INDEX post_recent ON post (created_at DESC) WHERE hidden_at IS NULL;

CREATE TABLE post_media (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid NOT NULL REFERENCES post (id) ON DELETE CASCADE,
  position    integer NOT NULL CHECK (position BETWEEN 0 AND 9),
  object_key  text NOT NULL,
  alt_text    text NOT NULL,
  width       integer NOT NULL,
  height      integer NOT NULL,
  UNIQUE (post_id, position)
);

CREATE TABLE post_like (
  post_id     uuid NOT NULL REFERENCES post (id) ON DELETE CASCADE,
  account_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, account_id)
);

CREATE TABLE post_save (
  post_id     uuid NOT NULL REFERENCES post (id) ON DELETE CASCADE,
  account_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, account_id)
);
CREATE INDEX post_save_account ON post_save (account_id, created_at DESC);

CREATE TABLE comment (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id               uuid NOT NULL REFERENCES post (id) ON DELETE CASCADE,
  author_id             uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  body                  text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 500),
  like_count            integer NOT NULL DEFAULT 0,
  hidden_by_moderation  boolean NOT NULL DEFAULT false,
  created_at            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX comment_post ON comment (post_id, created_at);

-- Ranked-cursor snapshots (api.md §5): the rank is frozen at the first page
-- for the cursor's 24 h life.
CREATE TABLE feed_snapshot (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  fingerprint  text NOT NULL,
  post_ids     uuid[] NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE feed_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_snapshot FORCE ROW LEVEL SECURITY;
CREATE POLICY feed_snapshot_owner ON feed_snapshot USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

-- ── Trust and safety (§6.2, A-6) ────────────────────────────────────────

CREATE TABLE block (
  blocker_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  blocked_id  uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);
CREATE INDEX block_blocked ON block (blocked_id);

CREATE TABLE report (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id       uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  subject_kind      text NOT NULL CHECK (subject_kind IN ('post', 'comment', 'account')),
  subject_id        text NOT NULL,
  -- Snapshot of the reported content for the queue row.
  subject_preview   jsonb NOT NULL,
  reason            text NOT NULL CHECK (reason IN ('spam', 'inappropriate', 'counterfeit', 'harassment', 'other')),
  detail            text,
  status            text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'actioned', 'dismissed')),
  action            text CHECK (action IN ('hide_post', 'suspend_account', 'dismiss')),
  actioned_by       uuid REFERENCES account (id),
  actioned_at       timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE report ENABLE ROW LEVEL SECURITY;
ALTER TABLE report FORCE ROW LEVEL SECURITY;
CREATE POLICY report_reporter ON report USING (app_account_visible(reporter_id)) WITH CHECK (app_account_visible(reporter_id));

-- ── Orders (order-lifecycle.md; §5, §6.3, §6.5) ─────────────────────────

CREATE SEQUENCE order_number_seq START 1060;

CREATE TABLE request (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number         text NOT NULL UNIQUE DEFAULT ('APR-' || nextval('order_number_seq')),
  post_id              uuid REFERENCES post (id) ON DELETE SET NULL,
  -- Frozen at submit so the order survives the post being deleted.
  post_caption         text NOT NULL,
  post_thumb_url       text NOT NULL DEFAULT '',
  customer_account_id  uuid NOT NULL REFERENCES account (id),
  designer_id          uuid NOT NULL REFERENCES designer_profile (id),
  designer_account_id  uuid NOT NULL REFERENCES account (id),
  status               text NOT NULL DEFAULT 'requested' CHECK (status IN
                       ('requested', 'quoted', 'paid', 'in_progress', 'shipped', 'delivered', 'refunded', 'declined', 'disputed', 'cancelled')),
  notes                text NOT NULL DEFAULT '',
  budget_cents         bigint,
  quote_cents          bigint CHECK (quote_cents > 0),
  currency             char(3) NOT NULL DEFAULT 'NGN',
  due_at               timestamptz,
  target_date          date,
  tracking             text,
  decline_reason       text,
  dispute_reason       text,
  dispute_detail       text,
  -- §6.3: frozen at submit; sensitive PII.
  delivery             jsonb NOT NULL,
  -- §5: frozen copy of vault values + method + measured_at.
  snapshot             jsonb NOT NULL,
  snapshot_id          uuid NOT NULL DEFAULT gen_random_uuid(),
  quoted_at            timestamptz,
  shipped_at           timestamptz,
  terminal_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX request_customer ON request (customer_account_id, created_at DESC);
CREATE INDEX request_designer ON request (designer_id, created_at DESC);
CREATE INDEX request_open ON request (status) WHERE status IN ('quoted', 'paid', 'shipped');
ALTER TABLE request ENABLE ROW LEVEL SECURITY;
ALTER TABLE request FORCE ROW LEVEL SECURITY;
-- Party only (order-lifecycle.md §2); everyone else reads not_found.
CREATE POLICY request_party ON request
  USING (app_bypass() OR app_account() IN (customer_account_id, designer_account_id))
  WITH CHECK (app_bypass() OR app_account() IN (customer_account_id, designer_account_id));

CREATE FUNCTION app_request_visible(row_request uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT app_bypass() OR EXISTS (SELECT 1 FROM request r WHERE r.id = row_request)
$$;

CREATE TABLE order_event (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id  uuid NOT NULL REFERENCES request (id) ON DELETE CASCADE,
  -- State transitions and reminders (reminder_7, reminder_12).
  kind        text NOT NULL,
  actor       text NOT NULL CHECK (actor IN ('customer', 'designer', 'system', 'moderator')),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX order_event_request ON order_event (request_id, created_at);
ALTER TABLE order_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_event FORCE ROW LEVEL SECURITY;
CREATE POLICY order_event_party ON order_event USING (app_request_visible(request_id)) WITH CHECK (app_request_visible(request_id));

CREATE TABLE thread_message (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id         uuid NOT NULL REFERENCES request (id) ON DELETE CASCADE,
  author_account_id  uuid NOT NULL REFERENCES account (id),
  author_is_designer boolean NOT NULL,
  body               text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
  media_id           uuid REFERENCES media (id) ON DELETE SET NULL,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX thread_message_request ON thread_message (request_id, created_at);
ALTER TABLE thread_message ENABLE ROW LEVEL SECURITY;
ALTER TABLE thread_message FORCE ROW LEVEL SECURITY;
CREATE POLICY thread_message_party ON thread_message USING (app_request_visible(request_id)) WITH CHECK (app_request_visible(request_id));

-- ── Money (§5.2, §6.3, §6.4; decisions are commerce's, S-6) ─────────────

CREATE TABLE payment (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id          uuid NOT NULL UNIQUE REFERENCES request (id),
  provider            text NOT NULL DEFAULT 'paystack' CHECK (provider IN ('paystack', 'stripe')),
  -- pending: checkout started; held: charge settled into escrow.
  state               text NOT NULL CHECK (state IN ('pending', 'held', 'released', 'refunded')),
  reference           text NOT NULL UNIQUE,
  currency            char(3) NOT NULL,
  amount_cents        bigint NOT NULL CHECK (amount_cents > 0),
  platform_fee_cents  bigint NOT NULL DEFAULT 0,
  provider_ref        text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment FORCE ROW LEVEL SECURITY;
CREATE POLICY payment_party ON payment USING (app_request_visible(request_id)) WITH CHECK (app_request_visible(request_id));

CREATE TABLE payout (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id             uuid NOT NULL UNIQUE REFERENCES request (id),
  designer_id            uuid NOT NULL REFERENCES designer_profile (id),
  amount_cents           bigint NOT NULL,
  currency               char(3) NOT NULL,
  provider_transfer_ref  text,
  state                  text NOT NULL CHECK (state IN ('pending', 'paid', 'failed')),
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE payout ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout FORCE ROW LEVEL SECURITY;
CREATE POLICY payout_party ON payout USING (app_request_visible(request_id)) WITH CHECK (app_request_visible(request_id));

-- Every Paystack webhook, stored before anything acts on it (D5, S-12).
CREATE TABLE provider_event (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider      text NOT NULL,
  -- Paystack sends no event id; this is a hash of the raw body.
  provider_key  text NOT NULL,
  event         text NOT NULL,
  payload       jsonb NOT NULL,
  received_at   timestamptz NOT NULL DEFAULT now(),
  processed_at  timestamptz,
  outcome       text,
  UNIQUE (provider, provider_key)
);
ALTER TABLE provider_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_event FORCE ROW LEVEL SECURITY;
CREATE POLICY provider_event_system ON provider_event USING (app_bypass()) WITH CHECK (app_bypass());

-- Each money decision commerce sent, stored once (outcome ids are
-- deterministic, so a redelivered decision is a no-op).
CREATE TABLE payment_outcome (
  outcome_id   uuid PRIMARY KEY,
  kind         text NOT NULL,
  request_id   uuid,
  designer_id  uuid,
  reason       text,
  payload      jsonb NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  resolved_at  timestamptz
);
ALTER TABLE payment_outcome ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_outcome FORCE ROW LEVEL SECURITY;
CREATE POLICY payment_outcome_system ON payment_outcome USING (app_bypass()) WITH CHECK (app_bypass());

-- Append-only double entry (§5.2). Lines of one outcome sum to zero, which
-- the trigger below checks at commit.
CREATE TABLE ledger_entry (
  id          bigserial PRIMARY KEY,
  outcome_id  uuid NOT NULL REFERENCES payment_outcome (outcome_id),
  request_id  uuid NOT NULL REFERENCES request (id),
  account     text NOT NULL CHECK (account IN ('customer_funds', 'escrow', 'platform_fee', 'designer_payable', 'refund')),
  amount      bigint NOT NULL,
  currency    char(3) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ledger_entry_request ON ledger_entry (request_id);
ALTER TABLE ledger_entry ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entry FORCE ROW LEVEL SECURITY;
CREATE POLICY ledger_system ON ledger_entry USING (app_bypass()) WITH CHECK (app_bypass());

CREATE FUNCTION ledger_balanced() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT coalesce(sum(amount), 0) FROM ledger_entry WHERE outcome_id = NEW.outcome_id) <> 0 THEN
    RAISE EXCEPTION 'ledger lines of outcome % do not balance', NEW.outcome_id;
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ledger_entry_balanced AFTER INSERT ON ledger_entry
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ledger_balanced();

CREATE RULE ledger_entry_no_update AS ON UPDATE TO ledger_entry DO INSTEAD NOTHING;
CREATE RULE ledger_entry_no_delete AS ON DELETE TO ledger_entry DO INSTEAD NOTHING;

-- ── Notifications (§6.4) ────────────────────────────────────────────────

CREATE TABLE notification (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  kind         text NOT NULL,
  payload_ref  text NOT NULL,
  text         text NOT NULL,
  actor        jsonb,
  thumb_url    text,
  read_at      timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notification_account ON notification (account_id, created_at DESC);
ALTER TABLE notification ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification FORCE ROW LEVEL SECURITY;
CREATE POLICY notification_owner ON notification USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

-- ── Plumbing ────────────────────────────────────────────────────────────

-- Replays for Idempotency-Key requests (api.md §4).
CREATE TABLE idempotency_key (
  account_id    uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  scope         text NOT NULL,
  key           text NOT NULL,
  payload_hash  text NOT NULL,
  status        integer NOT NULL,
  response      jsonb NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, scope, key)
);
ALTER TABLE idempotency_key ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_key FORCE ROW LEVEL SECURITY;
CREATE POLICY idempotency_owner ON idempotency_key USING (app_account_visible(account_id)) WITH CHECK (app_account_visible(account_id));

-- Transactional outbox (§6.6).
CREATE TABLE outbox (
  id            bigserial PRIMARY KEY,
  event         text NOT NULL,
  message_key   text NOT NULL,
  payload       jsonb NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  published_at  timestamptz
);
CREATE INDEX outbox_unsent ON outbox (id) WHERE published_at IS NULL;
ALTER TABLE outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE outbox FORCE ROW LEVEL SECURITY;
-- Business transactions enqueue as the caller; only the publisher reads.
CREATE POLICY outbox_insert ON outbox FOR INSERT WITH CHECK (true);
CREATE POLICY outbox_system ON outbox USING (app_bypass());
