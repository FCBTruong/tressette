-- Base PostgreSQL migration scaffold.
-- Keep schema changes in this folder and apply them in order.

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(64) PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
