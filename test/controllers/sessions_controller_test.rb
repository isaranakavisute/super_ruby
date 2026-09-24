require "test_helper"

# Logins are checked against myuser / mypassword in the PostgreSQL user_password table.
class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { create_user_password_table }

  test "index" do
    get login_path
    assert_response :success
    assert_select "input[name=username]"
  end

  test "a user_password account signs in and goes to the shop" do
    assert_difference -> { User.count }, 1 do
      post login_path, params: { username: "alice", password: "secret-1" }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "alice", User.last.username

    follow_redirect!
    assert_select "header", /alice/
  end

  test "signing in again reuses the same local user" do
    post login_path, params: { username: "alice", password: "secret-1" }

    assert_no_difference -> { User.count } do
      post login_path, params: { username: "alice", password: "secret-1" }
    end
  end

  test "wrong password shows a red error under the password field" do
    post login_path, params: { username: "alice", password: "wrong" }

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
    assert_select "input[name=password] + p#login-error.text-red-600", "Password is incorrect"
    assert_select "input[name=username][value=alice]"
  end

  test "another user's password is rejected" do
    post login_path, params: { username: "alice", password: "secret-2" }

    assert_response :unprocessable_content
  end

  test "unknown username shows the same error" do
    post login_path, params: { username: "nobody", password: "secret-1" }

    assert_response :unprocessable_content
    assert_select "#login-error", "Password is incorrect"
  end

  test "local users can no longer sign in with their Rails password" do
    post login_path, params: { username: "admin", password: "admin" }

    assert_response :unprocessable_content
  end

  test "shows an error when the database cannot be reached" do
    original = UserPassword.method(:authenticate)
    UserPassword.define_singleton_method(:authenticate) { |*| raise ActiveRecord::ConnectionNotEstablished }
    begin
      post login_path, params: { username: "alice", password: "secret-1" }
    ensure
      UserPassword.define_singleton_method(:authenticate, original)
    end

    assert_response :service_unavailable
    assert_select "#login-error", /Could not reach the user database/
  end

  test "no error is shown before signing in" do
    get login_path
    assert_select "#login-error", count: 0
  end

  test "destroy" do
    sign_in_as(users(:one))

    delete login_path

    assert_redirected_to login_path
    assert_empty cookies[:session_id]
  end
end
