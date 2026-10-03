require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  # Let click_button / fill_in find elements by their aria-label (e.g. the icon-only eye button)
  Capybara.enable_aria_label = true

  # Tests use the remote PostgreSQL (mydb), where a page with several queries can take over 2 seconds (the default)
  Capybara.default_max_wait_time = 6

  # Signs in through the login form and the 2FA page, for an account with 2FA on (see enable_two_factor_for)
  def sign_in_with_two_factor(username, password)
    visit login_path
    fill_in "Username", with: username
    fill_in "Password", with: password
    fill_in_login_captcha
    click_button "Sign in"

    assert_selector "h1", text: "Enter your code"
    fill_in "Code", with: otp_code
    click_button "Verify"
  end

  # Waits for the CAPTCHA image to load, then types the answer of that (the latest) challenge
  def fill_in_login_captcha
    image = find("img[alt^='CAPTCHA']")
    Timeout.timeout(5) { sleep 0.05 until image.evaluate_script("this.complete && this.naturalWidth > 0") }
    fill_in "Type the characters in the image", with: LoginCaptcha.order(:id).last.answer
  end
end
