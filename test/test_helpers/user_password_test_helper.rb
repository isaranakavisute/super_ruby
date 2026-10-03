module UserPasswordTestHelper
  # The test database (local Supabase) has no user_password table, so create a temporary one
  # with known accounts. It is dropped automatically when the test's transaction is rolled back.
  def create_user_password_table
    PostgresRecord.connection.execute(<<~SQL)
      CREATE TEMP TABLE user_password (
        id serial PRIMARY KEY, myuser varchar, mypassword varchar,
        otp_secret text, otp_enabled_at timestamptz, otp_last_used_at timestamptz, otp_recovery_digests text[] NOT NULL DEFAULT '{}'
      ) ON COMMIT DROP;
      INSERT INTO user_password (myuser, mypassword) VALUES ('bob', 'secret-2'), ('alice', 'secret-1');
    SQL
    UserPassword.reset_column_information
  end
end

ActiveSupport.on_load(:active_support_test_case) { include UserPasswordTestHelper }
