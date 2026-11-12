-- Operational retry throttle for the bounded Paystack pending-payment sweep.
ALTER TABLE payment ADD COLUMN last_verification_at timestamptz;
