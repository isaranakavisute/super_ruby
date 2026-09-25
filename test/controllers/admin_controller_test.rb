require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_user_password_table
    create_products_table
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('admin', 'admin-pass')")
  end

  test "admin is sent to the Admin Panel after signing in" do
    post login_path, params: { username: "admin", password: "admin-pass" }

    assert_redirected_to admin_panel_path
    follow_redirect!
    assert_select "h1", /Admin Panel/
  end

  test "admin goes to the Admin Panel even if another page was asked for first" do
    get root_path
    post login_path, params: { username: "admin", password: "admin-pass" }

    assert_redirected_to admin_panel_path
  end

  test "other users still go to the shop" do
    post login_path, params: { username: "alice", password: "secret-1" }

    assert_redirected_to root_path
  end

  test "Admin Panel has the users table, loaded from the /user API" do
    sign_in_as users(:admin)

    get admin_panel_path

    assert_response :success
    assert_select "[data-controller=admin-users][data-admin-users-url-value=?]", user_path
    assert_select "table.border-black th.border-black", 3
    assert_select "th", "Password"
  end

  test "other signed-in users cannot open the Admin Panel" do
    sign_in_as users(:one)

    get admin_panel_path

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".bg-red-100", "Only the admin can open the Admin Panel."
  end

  test "visitors must sign in first" do
    get admin_panel_path

    assert_redirected_to login_path
  end
end
