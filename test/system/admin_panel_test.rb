require "application_system_test_case"

class AdminPanelTest < ApplicationSystemTestCase
  setup do
    create_user_password_table
    UserPassword.connection.execute("INSERT INTO user_password (myuser, mypassword) VALUES ('admin', 'admin-pass'), ('tiny', 'ab')")
  end

  test "admin signs in and sees every user, with the last 3 password characters masked" do
    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"

    assert_selector "h1", text: "Admin Panel"
    assert_text "4 users"

    rows = all("tbody tr").map { |tr| tr.all("td").map(&:text) }
    assert_equal [
      [ "1", "bob", "secre***" ],
      [ "2", "alice", "secre***" ],
      [ "3", "admin", "admin-p***" ],
      [ "4", "tiny", "**" ]
    ], rows
    assert_no_text "secret-1"
  end
end
