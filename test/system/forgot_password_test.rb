require "application_system_test_case"

class ForgotPasswordTest < ApplicationSystemTestCase
  setup do
    create_user_password_table
    create_products_table
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('admin', 'admin-pass')")
    enable_two_factor_for("admin")
    enable_two_factor_for("bob")
  end

  test "user asks for a reset, admin resets it, user signs in with 123456" do
    visit login_path
    click_link "Forgot password?"
    assert_selector "h1", text: "Forgot password" # wait: the login page has a Username field too
    fill_in "Username", with: "bob"
    click_button "Send request"
    assert_text "Your request has been sent to the admin."

    sign_in_with_two_factor("admin", "admin-pass")
    assert_selector "nav a", text: /REQUESTS\s+1/

    click_link "REQUESTS"
    accept_confirm("Reset the password for bob to 123456?") { click_button "Reset to 123456" }
    assert_text "Password for bob has been reset to 123456. Please let them know."
    assert_text "No requests are waiting."
    assert_no_selector "nav a span.bg-red-600"

    click_button "Sign out"
    sign_in_with_two_factor("bob", "123456")
    assert_current_path root_path
  end
end
