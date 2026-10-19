-- Runs once, on an empty data directory. api/common connects as
-- apparule_app: a non-superuser that owns its database, so FORCE row-level
-- security applies to it (S-11). Superusers bypass RLS entirely.
CREATE ROLE apparule_app LOGIN PASSWORD 'apparule_app' NOSUPERUSER NOBYPASSRLS;
CREATE DATABASE apparule OWNER apparule_app;
