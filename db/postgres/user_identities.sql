-- user_identities table in the PostgreSQL database (mydb), used by the UserIdentity model.
-- Rails migrations never run against that database (database_tasks: false in config/database.yml),
-- so create it with this file, e.g.: psql -h <host> -U <user> -d <db> -f db/postgres/user_identities.sql
-- Each row links a Google or Facebook account (provider + uid) to one user_password account.
-- Safe to run again.
CREATE TABLE IF NOT EXISTS user_identities (
  id               bigserial PRIMARY KEY,
  user_password_id integer NOT NULL REFERENCES user_password (id) ON DELETE CASCADE,
  provider         varchar NOT NULL,   -- "google_oauth2" or "facebook"
  uid              varchar NOT NULL,   -- the user's id at Google / Facebook (never changes)
  email            varchar,            -- as reported by the provider, for display only
  name             varchar,
  created_at       timestamp(6) NOT NULL,
  updated_at       timestamp(6) NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS index_user_identities_on_provider_and_uid ON user_identities (provider, uid);
-- One Google and one Facebook account at most per user
CREATE UNIQUE INDEX IF NOT EXISTS index_user_identities_on_user_password_id_and_provider ON user_identities (user_password_id, provider);
