class UserPasswordsController < ApplicationController
  # Public JSON API used by Postman and other non-browser clients, so no login is required
  allow_unauthenticated_access

  rescue_from ActiveRecord::ConnectionNotEstablished do |e|
    render json: { error: "Could not connect to PostgreSQL: #{e.message}" }, status: :service_unavailable
  end

  def index
    render json: UserPassword.order(:id)
  end
end
