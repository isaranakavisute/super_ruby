require "application_system_test_case"

class LoginPasswordVisibilityTest < ApplicationSystemTestCase
  test "the eye button shows and hides the password" do
    visit login_path
    fill_in "Password", with: "my-secret"

    assert_selector "input#password[type=password]"
    assert_selector "button[aria-label='Show password'][aria-pressed=false]"

    click_button "Show password"

    assert_selector "input#password[type=text]"
    assert_selector "button[aria-label='Hide password'][aria-pressed=true]"
    assert_equal "my-secret", find("#password").value
    assert_equal "password", evaluate_script("document.activeElement.id")

    click_button "Hide password"

    assert_selector "input#password[type=password]"
    assert_selector "button[aria-label='Show password'][aria-pressed=false]"
  end
end
