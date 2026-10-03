require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  setup do
    create_user_password_table
    create_products_table
  end

  test "register from the login page, then sign in with the new account" do
    visit login_path
    click_link "Register"

    assert_selector "h1", text: "Register"
    fill_in "Username", with: "newbie"
    fill_in "Password", with: "secret-3"
    fill_in "Confirm password", with: "secret-4"
    click_button "Register"

    assert_text "Confirm password doesn't match the password"

    fill_in "Password", with: "secret-3"
    fill_in "Confirm password", with: "secret-3"
    click_button "Register"

    assert_selector "h1", text: "Sign in"
    assert_text "Registration successful. Please sign in."
    assert_field "Username", with: "newbie"

    fill_in "Password", with: "secret-3"
    fill_in_login_captcha
    click_button "Sign in"

    # First sign-in: 2FA must be set up before reaching the shop
    assert_selector "h1", text: "Set up two-factor authentication"
    assert_selector "svg path" # the QR code
    find("summary", text: "Can't scan it?").click
    secret = find("[data-testid=otp-secret]").text.delete(" ")

    fill_in "3. Enter the 6-digit code shown in the app", with: "000000"
    click_button "Turn on two-factor authentication"
    assert_text "That code is not correct."

    fill_in "3. Enter the 6-digit code shown in the app", with: otp_code(secret)
    click_button "Turn on two-factor authentication"

    assert_selector "h1", text: "Two-factor authentication is on"
    codes = all("ul[aria-label='Recovery codes'] li").map(&:text)
    assert_equal 10, codes.size
    click_link "I've saved my codes, continue"
    assert_text "👤 newbie"

    # Next sign-in asks for a code; a recovery code works too (once)
    click_button "Sign out"
    fill_in "Username", with: "newbie"
    fill_in "Password", with: "secret-3"
    fill_in_login_captcha
    click_button "Sign in"
    assert_selector "h1", text: "Enter your code"
    fill_in "Code", with: codes.first
    click_button "Verify"
    assert_text "You signed in with a recovery code. 9 recovery codes left."
    assert_text "👤 newbie"
  end
end
