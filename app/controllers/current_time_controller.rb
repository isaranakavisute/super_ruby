class CurrentTimeController < ApplicationController
  # Public JSON API used by Postman and other non-browser clients, so no login is required
  allow_unauthenticated_access

  def show
    now = Time.current

    render json: {
      day: now.strftime("%A"),
      date: now.to_date.iso8601,
      time: now.strftime("%H:%M:%S"),
      time_zone: now.time_zone.name,
      iso8601: now.iso8601
    }
  end
end
