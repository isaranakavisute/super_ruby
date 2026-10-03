module SocialLoginTestHelper
  # A temporary user_identities table for every test, so tests never touch the real table in mydb.
  # (No foreign key: the temporary user_password table isn't always there.)
  def create_user_identities_table
    PostgresRecord.connection.execute(<<~SQL)
      CREATE TEMP TABLE user_identities (
        id bigserial PRIMARY KEY, user_password_id integer NOT NULL, provider varchar NOT NULL, uid varchar NOT NULL,
        email varchar, name varchar, created_at timestamp(6) NOT NULL, updated_at timestamp(6) NOT NULL,
        UNIQUE (provider, uid), UNIQUE (user_password_id, provider)
      ) ON COMMIT DROP;
    SQL
    UserIdentity.reset_column_information
  end

  # What Google / Facebook would send back after the user approves (OmniAuth test mode)
  def mock_social_login(provider, uid:, email: nil, name: nil)
    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new(provider: provider.to_s, uid: uid, info: { email: email, name: name })
  end
end

OmniAuth.config.test_mode = true

ActiveSupport.on_load(:active_support_test_case) do
  include SocialLoginTestHelper
  setup :create_user_identities_table
  teardown { OmniAuth.config.mock_auth.except!(:google_oauth2, :facebook) }
end
