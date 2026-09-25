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
    assert_select "table.border-black th.border-black", 4
    assert_select "th.text-center", "Actions"
    assert_select "[data-admin-users-reset-url-value=?]", "/admin/users/__ID__/reset_password"
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

  test "admin resets one user's password to 123456" do
    sign_in_as users(:admin)
    bob = UserPassword.find_by!(myuser: "bob")

    post admin_reset_password_path(bob), as: :json

    assert_response :success
    assert_equal({ "id" => bob.id, "myuser" => "bob", "mypassword" => "123456" }, response.parsed_body)
    assert_equal "123456", bob.reload.mypassword
    assert_equal "secret-1", UserPassword.find_by!(myuser: "alice").mypassword, "other users must not change"
  end

  test "the reset password can be used to sign in" do
    sign_in_as users(:admin)
    post admin_reset_password_path(UserPassword.find_by!(myuser: "bob")), as: :json
    sign_out

    post login_path, params: { username: "bob", password: "123456" }

    assert_redirected_to root_path
  end

  test "other users cannot reset passwords" do
    sign_in_as users(:one)
    bob = UserPassword.find_by!(myuser: "bob")

    post admin_reset_password_path(bob), as: :json

    assert_response :forbidden
    assert_equal "secret-2", bob.reload.mypassword
  end

  test "visitors cannot reset passwords" do
    post admin_reset_password_path(UserPassword.find_by!(myuser: "bob")), as: :json

    assert_response :redirect
    assert_equal "secret-2", UserPassword.find_by!(myuser: "bob").mypassword
  end

  test "resetting an unknown user returns 404" do
    sign_in_as users(:admin)

    post admin_reset_password_path(id: 999_999), as: :json

    assert_response :not_found
  end

  test "admin saves a new username and password for one user" do
    sign_in_as users(:admin)
    bob = UserPassword.find_by!(myuser: "bob")

    patch admin_user_path(bob), params: { myuser: "bobby", mypassword: "new-pass-1" }, as: :json

    assert_response :success
    assert_equal({ "id" => bob.id, "myuser" => "bobby", "mypassword" => "new-pass-1" }, response.parsed_body)
    assert_equal [ "bobby", "new-pass-1" ], bob.reload.slice(:myuser, :mypassword).values
    assert_equal "secret-1", UserPassword.find_by!(myuser: "alice").mypassword, "other users must not change"
  end

  test "saving invalid values returns the errors and changes nothing" do
    sign_in_as users(:admin)
    bob = UserPassword.find_by!(myuser: "bob")

    patch admin_user_path(bob), params: { myuser: "alice", mypassword: "abc" }, as: :json

    assert_response :unprocessable_content
    errors = response.parsed_body["errors"]
    assert_equal [ "Username is already taken" ], errors["myuser"]
    assert_match(/Password is too short/, errors["mypassword"].first)
    assert_equal [ "bob", "secret-2" ], bob.reload.slice(:myuser, :mypassword).values
  end

  test "the admin account cannot be renamed, but its password can change" do
    sign_in_as users(:admin)
    admin = UserPassword.find_by!(myuser: "admin")

    patch admin_user_path(admin), params: { myuser: "boss", mypassword: "admin-pass" }, as: :json
    assert_response :unprocessable_content
    assert_equal [ "The admin account cannot be renamed" ], response.parsed_body.dig("errors", "myuser")

    patch admin_user_path(admin), params: { myuser: "admin", mypassword: "better-pass" }, as: :json
    assert_response :success
    assert_equal [ "admin", "better-pass" ], admin.reload.slice(:myuser, :mypassword).values
  end

  test "other users cannot edit accounts" do
    sign_in_as users(:one)
    bob = UserPassword.find_by!(myuser: "bob")

    patch admin_user_path(bob), params: { myuser: "hacked", mypassword: "hacked-1" }, as: :json

    assert_response :forbidden
    assert_equal "bob", bob.reload.myuser
  end

  test "left menu has USER and PRODUCT, with the current screen highlighted" do
    sign_in_as users(:admin)

    get admin_panel_path
    assert_select "nav a[href=?]", admin_panel_path, text: /USER/
    assert_select "nav a[href=?]", admin_products_path, text: /PRODUCT/
    assert_select "nav a[aria-current=page]", text: /USER/

    get admin_products_path
    assert_select "nav a[aria-current=page]", text: /PRODUCT/
  end

  test "PRODUCT screen lists every column and every product" do
    sign_in_as users(:admin)

    get admin_products_path

    assert_response :success
    assert_select "h2", "Products"
    assert_equal Product.column_names, css_select("thead th").map(&:text)
    assert_select "tbody tr", Product.count
    assert_select "tbody tr:first-child td", Product.column_names.size
    assert_select "tbody td", "Wireless Bluetooth Earbuds"
    assert_select "tbody td", "1290"
  end

  test "other users cannot open the PRODUCT screen" do
    sign_in_as users(:one)

    get admin_products_path

    assert_redirected_to root_path
  end
end
