require "test_helper"

class UserPasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { create_user_password_table }

  test "returns all records, ordered by id, without signing in" do
    get user_url

    assert_response :success
    assert_equal [
      { "id" => 1, "myuser" => "bob", "mypassword" => "secret-2" },
      { "id" => 2, "myuser" => "alice", "mypassword" => "secret-1" }
    ], response.parsed_body
  end
end
