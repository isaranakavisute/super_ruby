require "test_helper"

class HelloControllerTest < ActionDispatch::IntegrationTest
  test "returns hello world" do
    get root_url
    assert_response :success
    assert_equal "Hello, world!", response.body
  end
end
