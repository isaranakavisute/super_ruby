require "test_helper"

class ForgotPasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { create_user_password_table }

  test "login page links to Forgot password" do
    get login_path

    assert_select "a[href=?]", forgot_password_path, text: "Forgot password?"
  end

  test "Forgot password page asks for the username" do
    get forgot_password_path

    assert_response :success
    assert_select "h1", "Forgot password"
    assert_select "input[name=username][required]"
  end

  test "a known username creates a request for the admin" do
    assert_difference -> { PasswordResetRequest.pending.count }, 1 do
      post forgot_password_path, params: { username: " Bob " }
    end

    assert_redirected_to login_path
    assert_equal ForgotPasswordsController::SENT_MESSAGE, flash[:notice]
    assert_equal "bob", PasswordResetRequest.last.username, "stored with the account's own spelling"
    assert_equal "secret-2", UserPassword.find_by!(myuser: "bob").mypassword, "the password is not changed yet"
  end

  test "asking again while a request is waiting does not add another" do
    post forgot_password_path, params: { username: "bob" }

    assert_no_difference -> { PasswordResetRequest.count } do
      post forgot_password_path, params: { username: "bob" }
    end
  end

  test "an unknown username shows the same message but creates nothing" do
    assert_no_difference -> { PasswordResetRequest.count } do
      post forgot_password_path, params: { username: "nobody" }
    end

    assert_redirected_to login_path
    assert_equal ForgotPasswordsController::SENT_MESSAGE, flash[:notice]
  end

  test "a blank username shows an error" do
    post forgot_password_path, params: { username: "  " }

    assert_response :unprocessable_content
    assert_select "#forgot-error", "Please enter your username"
  end
end
