require "application_system_test_case"

class SocialLoginTest < ApplicationSystemTestCase
  setup do
    create_user_password_table
    create_products_table
  end

  test "Continue with Google goes straight to Google (no username, password or CAPTCHA), then 2FA setup" do
    mock_social_login(:google_oauth2, uid: "g-777", email: "somchai.k@gmail.com", name: "Somchai K")
    visit login_path

    click_button "Continue with Google"

    assert_selector "h1", text: "Set up two-factor authentication"
    assert UserPassword.exists?(myuser: "somchai.k")
  end

  test "Account page shows Google and Facebook with Connect buttons" do
    enable_two_factor_for("bob")
    sign_in_with_two_factor("bob", "secret-2")
    click_link "Account"

    assert_selector "h1", text: "Account"
    assert_selector "li", text: /Google\s+Not connected/
    assert_selector "li", text: /Facebook\s+Not connected/
  end
end
