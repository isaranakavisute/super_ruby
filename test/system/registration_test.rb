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
    click_button "Sign in"

    assert_text "👤 newbie"
  end
end
