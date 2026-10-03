class UserPasswordsController < ApplicationController
  # Public JSON API used by Postman and other non-browser clients, so no login is required
  allow_unauthenticated_access

  rescue_from ActiveRecord::ConnectionNotEstablished do |e|
    render json: { error: "Could not connect to PostgreSQL: #{e.message}" }, status: :service_unavailable
  end

  # Only these columns; never the 2FA columns (otp_secret, otp_recovery_digests, ...)
  PUBLIC_COLUMNS = %i[ id myuser mypassword ].freeze

  def index
    render json: UserPassword.order(:id).select(*PUBLIC_COLUMNS).as_json(only: PUBLIC_COLUMNS)
  end
end
