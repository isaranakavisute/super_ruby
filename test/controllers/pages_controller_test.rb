require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "the privacy policy is public and explains Google / Facebook data and deletion" do
    get privacy_path

    assert_response :success
    assert_select "h1", "Privacy policy"
    assert_select "li", /Google or Facebook account ID/
    assert_select "section#data-deletion h2", "Deleting your data"
  end

  test "the login page links to the privacy policy" do
    create_user_password_table
    get login_path

    assert_select "a[href=?]", privacy_path, text: "Privacy policy"
  end
end
