module ProductTestHelper
  # The test database (local Supabase) has no products table, so create a temporary one with
  # known products. It is dropped automatically when the test's transaction is rolled back.
  def create_products_table
    PostgresRecord.connection.execute(<<~SQL)
      CREATE TEMP TABLE products (
        id bigserial PRIMARY KEY, name varchar NOT NULL UNIQUE, category varchar NOT NULL, emoji varchar NOT NULL,
        price integer NOT NULL, original_price integer, rating numeric(2,1) NOT NULL DEFAULT 0,
        sold_count integer NOT NULL DEFAULT 0, location varchar NOT NULL,
        created_at timestamp(6) NOT NULL DEFAULT now(), updated_at timestamp(6) NOT NULL DEFAULT now()
      ) ON COMMIT DROP;
      INSERT INTO products (name, category, emoji, price, original_price, rating, sold_count, location) VALUES
        ('Wireless Bluetooth Earbuds', 'Electronics', '🎧', 599, 1290, 4.8, 12500, 'Bangkok'),
        ('Oversized Cotton T-Shirt', 'Fashion', '👕', 159, NULL, 4.8, 31000, 'Bangkok'),
        ('Thai Jasmine Rice 5kg', 'Groceries', '🍚', 189, NULL, 4.9, 42100, 'Suphan Buri');
    SQL
    Product.reset_column_information
  end
end

ActiveSupport.on_load(:active_support_test_case) { include ProductTestHelper }
