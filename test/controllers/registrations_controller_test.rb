require "test_helper"

# New accounts are added to the PostgreSQL user_password table (a temporary copy in tests).
class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_user_password_table
    create_products_table
  end

  test "login page has a Register button that opens the registration page" do
    get login_path
    assert_select "a[href=?]", register_path, text: "Register"

    get register_path
    assert_response :success
    assert_select "h1", "Register"
    assert_select "input[name=username]"
    assert_select "input[name=password][type=password]"
    assert_select "input[name=password_confirmation][type=password]"
  end

  test "registering adds the account and sends the user back to the login page" do
    assert_difference -> { UserPassword.count }, 1 do
      post register_path, params: { username: "newbie", password: "secret-3", password_confirmation: "secret-3" }
    end

    assert_redirected_to login_path(username: "newbie")
    assert_equal "secret-3", UserPassword.find_by!(myuser: "newbie").mypassword
    assert_nil cookies[:session_id], "registering should not sign the user in"

    follow_redirect!
    assert_select ".bg-green-100", "Registration successful. Please sign in."
    assert_select "input[name=username][value=newbie]"
  end

  test "the new account can sign in" do
    post register_path, params: { username: "newbie", password: "secret-3", password_confirmation: "secret-3" }

    post login_path, params: { username: "newbie", password: "secret-3" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "username that is already taken is rejected, whatever the case" do
    assert_no_difference -> { UserPassword.count } do
      post register_path, params: { username: "Alice", password: "secret-3", password_confirmation: "secret-3" }
    end

    assert_response :unprocessable_content
    assert_select "#username-error", /Username is already taken/
    assert_select "input[name=username][value=Alice]"
  end

  test "passwords that don't match are rejected" do
    assert_no_difference -> { UserPassword.count } do
      post register_path, params: { username: "newbie", password: "secret-3", password_confirmation: "secret-4" }
    end

    assert_response :unprocessable_content
    assert_select "#password-confirmation-error", /Confirm password doesn't match the password/
  end

  test "short passwords and invalid usernames are rejected" do
    post register_path, params: { username: "new user!", password: "abc", password_confirmation: "abc" }

    assert_response :unprocessable_content
    assert_select "#username-error", /can only contain letters, numbers/
    assert_select "#password-error", /Password is too short/
  end

  test "blank fields are rejected" do
    post register_path, params: { username: "", password: "", password_confirmation: "" }

    assert_response :unprocessable_content
    assert_select "#username-error", /Username can't be blank/
    assert_select "#password-error", /Password can't be blank/
  end
end
