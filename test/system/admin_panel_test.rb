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
      [ "1", "bob", "secre***", "Reset Password" ],
      [ "2", "alice", "secre***", "Reset Password" ],
      [ "3", "admin", "admin-p***", "Reset Password" ],
      [ "4", "tiny", "**", "Reset Password" ]
    ], rows
    assert_no_text "secret-1"
  end

  test "Reset Password resets only that user's password to 123456" do
    # Tests normally skip CSRF checks; turn them on to prove the button sends the page's token
    ActionController::Base.allow_forgery_protection = true

    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"
    assert_text "4 users"

    bob_row = find("tbody tr", text: "bob")
    accept_confirm("Reset the password for bob to 123456?") do
      bob_row.click_button "Reset Password"
    end

    assert_text "Password for bob has been reset."
    assert_selector "tbody tr", text: "bob", count: 1
    assert_equal [ "1", "bob", "123***", "Reset Password" ], find("tbody tr", text: "bob").all("td").map(&:text)
    assert_equal "123456", UserPassword.find_by!(myuser: "bob").mypassword
    assert_equal "secret-1", UserPassword.find_by!(myuser: "alice").mypassword
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "cancelling the confirmation changes nothing" do
    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"
    assert_text "4 users"

    dismiss_confirm { find("tbody tr", text: "bob").click_button "Reset Password" }

    assert_equal "secret-2", UserPassword.find_by!(myuser: "bob").mypassword
    assert_text "4 users"
  end

  test "pencil opens a dialog with the user's details, and Save updates the database" do
    ActionController::Base.allow_forgery_protection = true

    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"
    assert_text "4 users"

    click_button "Edit bob"

    within "dialog[open]" do
      assert_text "Edit user"
      assert_field "Username", with: "bob"
      assert_field "Password", with: "secret-2", type: "password"

      fill_in "Username", with: "alice"
      click_button "Save"
      assert_text "Username is already taken"

      fill_in "Username", with: "bobby"
      fill_in "Password", with: "new-pass-1"
      click_button "Save"
    end

    assert_no_selector "dialog[open]"
    assert_text "bobby has been saved."
    assert_equal [ "1", "bobby", "new-pas***", "Reset Password" ], find("tbody tr", text: "bobby").all("td").map(&:text)
    assert_equal [ "bobby", "new-pass-1" ], UserPassword.find(1).slice(:myuser, :mypassword).values
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "Cancel closes the dialog without saving" do
    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"
    assert_text "4 users"

    click_button "Edit bob"
    within("dialog[open]") do
      fill_in "Username", with: "changed"
      click_button "Cancel"
    end

    assert_no_selector "dialog[open]"
    assert_equal "bob", UserPassword.find(1).myuser
  end

  test "left menu switches between the USER and PRODUCT screens" do
    create_products_table
    visit login_path
    fill_in "Username", with: "admin"
    fill_in "Password", with: "admin-pass"
    click_button "Sign in"
    assert_text "4 users"

    click_link "PRODUCT"
    assert_selector "h2", text: "Products"
    assert_selector "thead th", text: "sold_count"
    assert_selector "tbody tr", count: 3

    click_link "USER"
    assert_selector "h2", text: "Users"
    assert_text "4 users"
  end
end
