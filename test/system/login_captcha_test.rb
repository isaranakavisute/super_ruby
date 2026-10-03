require "application_system_test_case"

class LoginCaptchaSystemTest < ApplicationSystemTestCase
  setup { create_user_password_table }

  test "a wrong CAPTCHA shows an error and a new image; New image swaps the picture" do
    visit login_path
    fill_in "Username", with: "bob"
    fill_in "Password", with: "secret-2"
    fill_in "Type the characters in the image", with: "WRONG"
    click_button "Sign in"

    assert_text "The characters didn't match the image."

    image = find("img[alt^='CAPTCHA']")
    old_src = image[:src]
    click_button "New image"
    assert_not_equal old_src, find("img[alt^='CAPTCHA']")[:src]

    fill_in "Password", with: "secret-2"
    fill_in_login_captcha
    click_button "Sign in"
    assert_selector "h1", text: "Set up two-factor authentication"
  end
end
