require "test_helper"

class CurrentTimeControllerTest < ActionDispatch::IntegrationTest
  test "returns the current day and time" do
    travel_to Time.zone.local(2026, 9, 23, 14, 30, 5) do
      get test_url
    end

    assert_response :success
    assert_equal(
      {
        "day" => "Wednesday",
        "date" => "2026-09-23",
        "time" => "14:30:05",
        "time_zone" => "Bangkok",
        "iso8601" => "2026-09-23T14:30:05+07:00"
      },
      response.parsed_body
    )
  end
end
