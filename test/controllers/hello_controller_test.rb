require "test_helper"

class HelloControllerTest < ActionDispatch::IntegrationTest
  test "hello redirects to the login page when signed out" do
    get hello_path

    assert_redirected_to login_path
  end

  test "hello greets the signed-in user" do
    sign_in_as users(:one)

    get hello_path

    assert_response :success
    assert_select "h1", "Hello, world!"
    assert_select "strong", "one@example.com"
  end

  test "signing in sends the user back to the page they asked for" do
    create_user_password_table

    get hello_path
    post login_path, params: { username: "bob", password: "secret-2" }

    assert_redirected_to hello_url
    follow_redirect!
    assert_select "p", /signed in as/
  end
end
