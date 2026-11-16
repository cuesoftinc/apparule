-- Retained checkout references can represent real Paystack payments even
-- after a newer checkout replaces payment.reference. Track retries per
-- attempt so stale references can be verified and reconciled independently.
SELECT set_config('app.bypass_rls', 'on', true);

ALTER TABLE payment_attempt ADD COLUMN last_verification_at timestamptz;
CREATE INDEX payment_attempt_verification
  ON payment_attempt (last_verification_at, created_at DESC, reference)
  WHERE left(reference, 4) = 'apr_';
