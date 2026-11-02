-- Google SSO: the account is keyed by the Google subject, sessions are fenced
-- by an epoch, and one-time handoff codes are stored only as hashes.
ALTER TABLE account RENAME COLUMN firebase_uid TO google_sub;
ALTER TABLE account RENAME CONSTRAINT account_firebase_uid_key TO account_google_sub_key;
ALTER TABLE account ADD COLUMN session_epoch bigint NOT NULL DEFAULT 0;
CREATE INDEX account_email ON account (lower(email));

CREATE TABLE sso_handoff (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  body_code_hash    text NOT NULL UNIQUE,
  cookie_code_hash  text NOT NULL UNIQUE,
  account_id        uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  challenge         text NOT NULL,
  channel           text CHECK (channel IN ('body', 'cookie')),
  token_ciphertext  bytea,
  session_epoch     bigint NOT NULL DEFAULT 0,
  expires_at        timestamptz NOT NULL,
  consumed_at       timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sso_handoff_expires_at ON sso_handoff (expires_at);
ALTER TABLE sso_handoff ENABLE ROW LEVEL SECURITY;
ALTER TABLE sso_handoff FORCE ROW LEVEL SECURITY;
CREATE POLICY sso_handoff_system ON sso_handoff USING (app_bypass()) WITH CHECK (app_bypass());
