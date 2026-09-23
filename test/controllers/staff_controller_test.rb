require "test_helper"

# Runs against the real PostgreSQL database configured as "postgres" in config/database.yml.
class StaffControllerTest < ActionDispatch::IntegrationTest
  test "lists all staff records" do
    get staff_url

    assert_response :success
    body = response.parsed_body
    assert_equal Staff.count, body.size
    assert_equal Staff.order(:full_name).pluck(:id), body.pluck("id")
    assert_equal Staff.column_names.sort, body.first.keys.sort if body.any?
  end

  # Inserts below are rolled back at the end of each test by Rails' transactional tests

  test "adds staff with only a full_name" do
    assert_difference -> { Staff.count }, 1 do
      post add_staff_url, params: { full_name: "Test Person" }, as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "Test Person", body["full_name"]
    assert body["id"].present?
    assert_equal true, body["active"]
    assert_equal [], body["divisions"]
  end

  test "adds staff from a form-encoded body" do
    assert_difference -> { Staff.count }, 1 do
      post add_staff_url, params: { full_name: "John Doe" }
    end

    assert_response :created
    assert_equal "John Doe", response.parsed_body["full_name"]
  end

  test "rejects an empty body" do
    post add_staff_url, params: {}, as: :json

    assert_response :unprocessable_content
    assert_equal [ "Full name can't be blank" ], response.parsed_body["errors"]
  end

  test "adds staff with optional fields" do
    post add_staff_url, params: { full_name: "Jane Smith", gender: "F", divisions: [ "senior" ], job_title: "Teacher" }, as: :json

    assert_response :created
    assert_equal [ "senior" ], response.parsed_body["divisions"]
    assert_equal "Teacher", Staff.find(response.parsed_body["id"]).job_title
  end

  test "rejects staff without a full_name" do
    assert_no_difference -> { Staff.count } do
      post add_staff_url, params: { full_name: "", job_title: "Teacher" }, as: :json
    end

    assert_response :unprocessable_content
    assert_equal [ "Full name can't be blank" ], response.parsed_body["errors"]
  end

  test "rejects an invalid gender" do
    post add_staff_url, params: { full_name: "Test Person", gender: "X" }, as: :json

    assert_response :unprocessable_content
    assert_equal [ "Gender is not included in the list" ], response.parsed_body["errors"]
  end

  test "rejects a duplicate email" do
    post add_staff_url, params: { full_name: "First", email: "dupe@example.test" }, as: :json
    post add_staff_url, params: { full_name: "Second", email: "dupe@example.test" }, as: :json

    assert_response :unprocessable_content
    assert_match "staff_email_key", response.parsed_body["errors"].first
  end

  test "ignores id and created_at" do
    id = SecureRandom.uuid
    post add_staff_url, params: { full_name: "Test Person", id: id, created_at: "2000-01-01" }, as: :json

    assert_response :created
    assert_not_equal id, response.parsed_body["id"]
    assert_not response.parsed_body["created_at"].start_with?("2000")
  end
end
