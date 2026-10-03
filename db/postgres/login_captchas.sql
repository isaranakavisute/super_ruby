-- login_captchas table in the PostgreSQL database (mydb), used by the LoginCaptcha model.
-- Rails migrations never run against that database (database_tasks: false in config/database.yml),
-- so create it with this file, e.g.: psql -h <host> -U <user> -d <db> -f db/postgres/login_captchas.sql
-- Each row is one CAPTCHA shown on the login page. Only its id is kept in the user's session; the
-- row is deleted when the answer is checked, so a solved CAPTCHA can't be replayed. Safe to run again.
CREATE TABLE IF NOT EXISTS login_captchas (
  id         bigserial PRIMARY KEY,
  answer     varchar NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamp(6) NOT NULL,
  updated_at timestamp(6) NOT NULL
);

CREATE INDEX IF NOT EXISTS index_login_captchas_on_expires_at ON login_captchas (expires_at);
