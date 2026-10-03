-- Two-factor authentication columns for the user_password table in the PostgreSQL database (mydb).
-- Rails migrations never run against that database (database_tasks: false in config/database.yml),
-- so apply this file by hand, e.g.: psql -h <host> -U <user> -d <db> -f db/postgres/user_password_2fa.sql
-- Safe to run more than once. It only adds columns; existing data is not changed.
ALTER TABLE user_password
  ADD COLUMN IF NOT EXISTS otp_secret           text,                       -- authenticator app secret, encrypted by Rails (encrypts :otp_secret)
  ADD COLUMN IF NOT EXISTS otp_enabled_at       timestamptz,                -- when 2FA was set up; NULL = not set up yet
  ADD COLUMN IF NOT EXISTS otp_last_used_at     timestamptz,                -- time step of the last accepted code, so a code can't be used twice
  ADD COLUMN IF NOT EXISTS otp_recovery_digests text[] NOT NULL DEFAULT '{}'; -- SHA-256 of the unused recovery codes (never the codes themselves)
