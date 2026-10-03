module LoginCaptchaTestHelper
  # A temporary login_captchas table for every test, so tests never touch the real table in mydb.
  # It is dropped automatically when the test's transaction is rolled back.
  def create_login_captchas_table
    PostgresRecord.connection.execute(<<~SQL)
      CREATE TEMP TABLE login_captchas (
        id bigserial PRIMARY KEY, answer varchar NOT NULL, expires_at timestamptz NOT NULL,
        created_at timestamp(6) NOT NULL, updated_at timestamp(6) NOT NULL
      ) ON COMMIT DROP;
    SQL
    LoginCaptcha.reset_column_information
  end
end

module LoginCaptchaIntegrationTestHelper
  # Loads a CAPTCHA image (like the login page does) and returns its answer
  def solve_login_captcha
    get login_captcha_path
    LoginCaptcha.find(session[:login_captcha_id]).answer
  end

  # Submits the login form with the right CAPTCHA answer
  def post_login(username, password)
    post login_path, params: { username: username, password: password, captcha: solve_login_captcha }
  end
end

ActiveSupport.on_load(:active_support_test_case) do
  include LoginCaptchaTestHelper
  setup :create_login_captchas_table
end
ActiveSupport.on_load(:action_dispatch_integration_test) { include LoginCaptchaIntegrationTestHelper }
