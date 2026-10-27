-- Shared-bus request ids (shared-messaging.md rules 1, 9), one checkout
-- reference per payment attempt, and money that needs a human (§6.4).

SELECT set_config('app.bypass_rls', 'on', true);

-- Stored on the row, so a re-published message keeps its request_id.
ALTER TABLE outbox ADD COLUMN request_id text NOT NULL DEFAULT gen_random_uuid()::text;

-- The first result per request_id wins; later results are ignored.
CREATE TABLE result_claim (
  request_id  text PRIMARY KEY,
  event       text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE result_claim ENABLE ROW LEVEL SECURITY;
ALTER TABLE result_claim FORCE ROW LEVEL SECURITY;
CREATE POLICY result_claim_system ON result_claim USING (app_bypass()) WITH CHECK (app_bypass());

-- Every checkout reference with the amount it was started for; a charge
-- settles against this amount, never the current quote.
CREATE TABLE payment_attempt (
  reference     text PRIMARY KEY,
  request_id    uuid NOT NULL REFERENCES request (id),
  amount_cents  bigint NOT NULL CHECK (amount_cents > 0),
  currency      char(3) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX payment_attempt_request ON payment_attempt (request_id);
ALTER TABLE payment_attempt ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_attempt FORCE ROW LEVEL SECURITY;
CREATE POLICY payment_attempt_party ON payment_attempt USING (app_request_visible(request_id)) WITH CHECK (app_request_visible(request_id));
INSERT INTO payment_attempt (reference, request_id, amount_cents, currency, created_at)
  SELECT reference, request_id, amount_cents, currency, created_at FROM payment;

-- refund_needed: money taken that escrow must not hold. not_applied: an
-- outcome common could not store after retries.
ALTER TABLE payment_outcome ADD COLUMN attention text CHECK (attention IN ('refund_needed', 'not_applied'));
CREATE INDEX payment_outcome_attention ON payment_outcome (created_at) WHERE attention IS NOT NULL AND resolved_at IS NULL;
