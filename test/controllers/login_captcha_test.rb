require "test_helper"

class LoginCaptchaTest < ActionDispatch::IntegrationTest
  setup { create_user_password_table }

  test "login page shows the CAPTCHA image, a New image button and the answer field" do
    get login_path

    assert_select "img[src^=?][alt^=CAPTCHA]", login_captcha_path
    assert_select "button[aria-label=?]", "New image", text: "↻"
    assert_select "input[name=captcha][required][autocomplete=off]"
  end

  test "the image is a fresh, uncached PNG, and each load replaces the previous challenge" do
    get login_captcha_path
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal "no-store", response.headers["Cache-Control"]
    assert response.body.start_with?("\x89PNG".b)
    first_id = session[:login_captcha_id]

    get login_captcha_path
    assert_not_equal first_id, session[:login_captcha_id]
    assert_equal 1, LoginCaptcha.count, "the previous challenge is deleted"
  end

  test "answers use 5 easy-to-read characters" do
    answer = solve_login_captcha

    assert_match(/\A[#{LoginCaptcha::ALPHABET.join}]{5}\z/, answer)
    assert_no_match(/[01OIVZ]/, answer)
  end

  test "a wrong CAPTCHA is rejected before the password is checked" do
    solve_login_captcha

    post login_path, params: { username: "bob", password: "secret-2", captcha: "WRONG" }

    assert_response :unprocessable_content
    assert_select "#captcha-error", /didn't match/
    assert_select "#login-error", false, "no password message: the password wasn't checked"
    assert_nil session[:pending_two_factor]
  end

  test "signing in without loading an image is rejected" do
    post login_path, params: { username: "bob", password: "secret-2", captcha: "ABCDE" }

    assert_response :unprocessable_content
    assert_select "#captcha-error"
  end

  test "the answer is not case-sensitive and ignores spaces" do
    answer = solve_login_captcha

    post login_path, params: { username: "bob", password: "secret-2", captcha: " #{answer.downcase} " }

    assert_redirected_to two_factor_setup_path
  end

  test "a solved CAPTCHA can't be used again" do
    answer = solve_login_captcha
    post login_path, params: { username: "bob", password: "wrong-pass", captcha: answer }
    assert_select "#login-error", "Password is incorrect"

    post login_path, params: { username: "bob", password: "secret-2", captcha: answer }

    assert_response :unprocessable_content
    assert_select "#captcha-error"
    assert_equal 0, LoginCaptcha.count
  end

  test "a CAPTCHA expires after 10 minutes" do
    answer = solve_login_captcha

    travel 11.minutes
    post login_path, params: { username: "bob", password: "secret-2", captcha: answer }

    assert_response :unprocessable_content
    assert_select "#captcha-error"
  end
end
