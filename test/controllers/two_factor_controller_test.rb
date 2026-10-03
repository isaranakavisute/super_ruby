require "test_helper"

class TwoFactorControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_user_password_table
    create_products_table
  end

  test "a correct password alone does not sign in; first-timers must set up 2FA" do
    post_login("bob", "secret-2")

    assert_redirected_to two_factor_setup_path
    assert_nil cookies[:session_id].presence
    get root_path
    assert_redirected_to login_path
  end

  test "setup shows a QR code; the right code turns 2FA on and shows 10 recovery codes once" do
    post_login("bob", "secret-2")
    get two_factor_setup_path

    assert_response :success
    assert_select "svg path"
    secret = css_select("[data-testid=otp-secret]").text.delete(" ")
    assert_equal 32, secret.size

    post two_factor_setup_path, params: { code: "000000" }
    assert_response :unprocessable_content
    assert_select "#code-error", /not correct/
    assert_equal secret, css_select("[data-testid=otp-secret]").text.delete(" "), "same QR code after a wrong code"

    post two_factor_setup_path, params: { code: otp_code(secret) }
    assert_redirected_to two_factor_recovery_codes_path
    follow_redirect!
    assert_select "ul[aria-label='Recovery codes'] li", 10

    get two_factor_recovery_codes_path
    assert_redirected_to root_path, "codes are only shown once"

    bob = UserPassword.find_by!(myuser: "bob")
    assert bob.two_factor_enabled?
    assert_equal secret, bob.otp_secret
    raw = UserPassword.connection.select_value("SELECT otp_secret FROM user_password WHERE myuser = 'bob'")
    assert_not_includes raw, secret, "stored encrypted"
  end

  test "with 2FA on, sign-in asks for the code and rejects a wrong one" do
    enable_two_factor_for("bob")
    post_login("bob", "secret-2")
    assert_redirected_to two_factor_path

    post two_factor_path, params: { code: "000000" }
    assert_response :unprocessable_content
    assert_nil cookies[:session_id].presence

    post two_factor_path, params: { code: otp_code }
    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "a code cannot be used twice" do
    enable_two_factor_for("bob")
    sign_in_with_two_factor("bob", "secret-2")
    delete login_path

    post_login("bob", "secret-2")
    post two_factor_path, params: { code: otp_code }

    assert_response :unprocessable_content
    assert_select "#code-error", "That code has already been used. Wait for the next code in your app (they change every 30 seconds), then enter it."
  end

  test "a phone whose clock is a few seconds fast: the code that just appeared (the next one) is accepted" do
    enable_two_factor_for("bob")
    post_login("bob", "secret-2")

    post two_factor_path, params: { code: ROTP::TOTP.new(TwoFactorTestHelper::OTP_SECRET).at(30.seconds.from_now) }

    assert_redirected_to root_path
  end

  test "codes further away than one window, before or after, are still rejected" do
    enable_two_factor_for("bob")
    post_login("bob", "secret-2")
    totp = ROTP::TOTP.new(TwoFactorTestHelper::OTP_SECRET)

    [ 90.seconds.from_now, 90.seconds.ago ].each do |at|
      post two_factor_path, params: { code: totp.at(at) }
      assert_response :unprocessable_content
      assert_select "#code-error", /not correct/
    end
  end

  test "setup also accepts the next code" do
    post_login("bob", "secret-2")
    get two_factor_setup_path
    secret = css_select("[data-testid=otp-secret]").text.delete(" ")

    post two_factor_setup_path, params: { code: ROTP::TOTP.new(secret).at(30.seconds.from_now) }

    assert_redirected_to two_factor_recovery_codes_path
  end

  test "each recovery code works once" do
    code = enable_two_factor_for("bob").first
    post_login("bob", "secret-2")
    post two_factor_path, params: { code: code.upcase }
    assert_redirected_to root_path
    assert_equal "You signed in with a recovery code. 9 recovery codes left.", flash[:notice]
    delete login_path

    post_login("bob", "secret-2")
    post two_factor_path, params: { code: code }
    assert_response :unprocessable_content
  end

  test "the 2FA step expires after 10 minutes" do
    enable_two_factor_for("bob")
    post_login("bob", "secret-2")

    travel 11.minutes
    post two_factor_path, params: { code: otp_code }

    assert_redirected_to login_path
    assert_equal "Please sign in again.", flash[:alert]
  end

  test "the 2FA pages need the password step first" do
    get two_factor_path
    assert_redirected_to login_path

    get two_factor_setup_path
    assert_redirected_to login_path
  end

  test "the /user API never shows 2FA data" do
    enable_two_factor_for("bob")

    get user_path

    assert_equal %w[ id mypassword myuser ], response.parsed_body.first.keys.sort
    assert_not_includes response.body, TwoFactorTestHelper::OTP_SECRET
  end

  test "admin can reset a user's 2FA; they set it up again at the next sign-in" do
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('admin', 'admin-pass')")
    enable_two_factor_for("bob")
    bob = UserPassword.find_by!(myuser: "bob")
    sign_in_as users(:admin)

    post admin_reset_two_factor_path(bob), as: :json

    assert_response :success
    assert_not bob.reload.two_factor_enabled?
    assert_empty bob.otp_recovery_digests
    sign_out
    post_login("bob", "secret-2")
    assert_redirected_to two_factor_setup_path
  end

  test "other users cannot reset 2FA" do
    enable_two_factor_for("bob")
    sign_in_as users(:one)

    post admin_reset_two_factor_path(UserPassword.find_by!(myuser: "bob")), as: :json

    assert_response :forbidden
    assert UserPassword.find_by!(myuser: "bob").two_factor_enabled?
  end
end
