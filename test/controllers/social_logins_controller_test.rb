require "test_helper"

class SocialLoginsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_user_password_table
    create_products_table
  end

  # OmniAuth refuses the request and sends the user back to the login page
  def assert_rejected_social_login
    assert_match %r{\A/auth/failure\?.*strategy=google_oauth2}, response.location.delete_prefix("http://www.example.com")
    follow_redirect!
    assert_redirected_to login_path
    assert_match "Sign-in with Google didn't work", flash[:alert]
  end

  # Login page button → OmniAuth → (mock) Google / Facebook → callback
  def continue_with(provider)
    post social_login_path(provider)
    assert_redirected_to "/auth/#{provider}"
    follow_redirect! # OmniAuth test mode sends the browser straight to the callback
    follow_redirect!
  end

  test "login page has Continue with Google and Facebook buttons, in their own forms without the CAPTCHA" do
    get login_path

    assert_select "form[action=?] button", social_login_path("google_oauth2"), text: /Continue with Google/
    assert_select "form[action=?] button", social_login_path("facebook"), text: /Continue with Facebook/
    assert_select "form[action=?] input[name=captcha]", social_login_path("google_oauth2"), false
  end

  test "a first Google sign-in creates an account from the email, then asks for 2FA setup" do
    mock_social_login(:google_oauth2, uid: "g-123", email: "Somchai.K@gmail.com", name: "Somchai K")

    assert_difference -> { UserPassword.count } => 1, -> { UserIdentity.count } => 1 do
      continue_with "google_oauth2"
    end

    assert_redirected_to two_factor_setup_path
    assert_nil cookies[:session_id].presence, "not signed in until 2FA is done"
    account = UserPassword.find_by!(myuser: "somchai.k")
    assert_equal [ "google_oauth2", "g-123", "Somchai.K@gmail.com" ], account.identities.first.slice(:provider, :uid, :email).values
  end

  test "a username that's taken gets a number" do
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('bob', 'x'), ('bob2', 'x')")
    mock_social_login(:google_oauth2, uid: "g-1", email: "bob@gmail.com")

    continue_with "google_oauth2"

    assert UserPassword.exists?(myuser: "bob3")
  end

  test "Facebook without an email uses the name" do
    mock_social_login(:facebook, uid: "fb-9", name: "Malee Chai")

    continue_with "facebook"

    assert UserPassword.exists?(myuser: "malee.chai")
  end

  test "a linked Google account signs in to its own account, and 2FA completes the sign-in" do
    bob = UserPassword.find_by!(myuser: "bob")
    bob.identities.create!(provider: "google_oauth2", uid: "g-bob", email: "bob@gmail.com")
    enable_two_factor_for("bob")
    mock_social_login(:google_oauth2, uid: "g-bob", email: "bob@gmail.com")

    assert_no_difference -> { UserPassword.count } do
      continue_with "google_oauth2"
    end
    assert_redirected_to two_factor_path

    post two_factor_path, params: { code: otp_code }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "header", /bob/
  end

  test "no CAPTCHA is needed to continue with Google" do
    post social_login_path("google_oauth2")

    assert_redirected_to "/auth/google_oauth2"
    assert_equal "login", session[:social_login_pass]["intent"]
  end

  test "Google sign-in can't be started directly (e.g. from another website)" do
    get "/auth/google_oauth2"

    assert_rejected_social_login
  end

  test "the pass to start a sign-in expires after 2 minutes" do
    post social_login_path("google_oauth2")
    travel 3.minutes
    get "/auth/google_oauth2"

    assert_rejected_social_login
  end

  test "the pass works only once" do
    post social_login_path("google_oauth2")
    get "/auth/google_oauth2"
    assert_redirected_to "/auth/google_oauth2/callback"

    get "/auth/google_oauth2"
    assert_rejected_social_login
  end

  test "a signed-in user connects Facebook on the Account page, without a CAPTCHA" do
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('one', 'secret-9')")
    sign_in_as users(:one)
    mock_social_login(:facebook, uid: "fb-one", email: "one@example.com")

    post connect_social_login_path("facebook")
    assert_redirected_to "/auth/facebook"
    follow_redirect!
    follow_redirect!

    assert_redirected_to account_path
    assert_equal "Facebook is now connected. You can use it to sign in.", flash[:notice]
    follow_redirect!
    assert_select "li", /Facebook\s+one@example.com/
    assert_select "button", "Disconnect"
  end

  test "a Google account already connected to someone else can't be connected again" do
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('one', 'secret-9')")
    UserPassword.find_by!(myuser: "bob").identities.create!(provider: "google_oauth2", uid: "g-bob")
    sign_in_as users(:one)
    mock_social_login(:google_oauth2, uid: "g-bob")

    post connect_social_login_path("google_oauth2")
    follow_redirect!
    follow_redirect!

    assert_equal "That Google account is already connected to another user.", flash[:alert]
  end

  test "Disconnect removes the connection" do
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('one', 'secret-9')")
    identity = UserPassword.find_by!(myuser: "one").identities.create!(provider: "facebook", uid: "fb-one")
    sign_in_as users(:one)

    delete disconnect_social_login_path(identity)

    assert_redirected_to account_path
    assert_not UserIdentity.exists?(identity.id)
  end

  test "a cancelled Google sign-in returns to the login page with a message" do
    get auth_failure_path(message: "access_denied", strategy: "google_oauth2")

    assert_redirected_to login_path
    assert_equal "Sign-in with Google was cancelled. Please try again, or sign in with your password.", flash[:alert]
  end

  test "the CSRF tokens on the login page are accepted by Sign in and the Google button" do
    # Tests normally skip CSRF checks; turn them on to check the real (per-form) tokens on the page
    ActionController::Base.allow_forgery_protection = true
    get login_path
    google_token = css_select("form[action='#{social_login_path("google_oauth2")}'] input[name=authenticity_token]").first["value"]
    login_token = css_select("form[action='#{login_path}'] input[name=authenticity_token]").first["value"]

    post social_login_path("google_oauth2"), params: { authenticity_token: google_token }
    assert_redirected_to "/auth/google_oauth2"

    post login_path, params: { authenticity_token: login_token, username: "bob", password: "secret-2", captcha: solve_login_captcha }
    assert_redirected_to two_factor_setup_path
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
