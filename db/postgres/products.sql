-- products table in the PostgreSQL database (see .env.<environment>), used by the Product model.
-- Rails migrations never run against that database (database_tasks: false in config/database.yml),
-- so create it with this file, e.g.: psql -h <host> -U <user> -d <db> -f db/postgres/products.sql
CREATE TABLE IF NOT EXISTS products (
  id             bigserial PRIMARY KEY,
  name           varchar NOT NULL,
  category       varchar NOT NULL,
  emoji          varchar NOT NULL,
  price          integer NOT NULL,          -- in baht
  original_price integer,                   -- in baht; set when the product is on sale
  rating         numeric(2,1) NOT NULL DEFAULT 0,
  sold_count     integer NOT NULL DEFAULT 0,
  location       varchar NOT NULL,
  created_at     timestamp(6) NOT NULL,
  updated_at     timestamp(6) NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS index_products_on_name ON products (name);
CREATE INDEX IF NOT EXISTS index_products_on_category ON products (category);
