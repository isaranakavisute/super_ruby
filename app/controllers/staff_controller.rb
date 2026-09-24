class StaffController < ApplicationController
  # Public JSON API used by Postman and other non-browser clients, so no login is required
  allow_unauthenticated_access

  # JSON API endpoint called by non-browser clients, so there is no CSRF token to check
  skip_forgery_protection only: :create

  # Fields are read from the top level (full_name=..., not staff[full_name]=...) for both
  # form and JSON bodies, so don't also copy JSON fields under a "staff" key
  wrap_parameters false

  # Every column except the ones the database fills in itself (id, created_at)
  PERMITTED_ATTRIBUTES = [
    :staff_ref, :title, :forename, :middle_names, :surname, :full_name, :initials, :nickname,
    :gender, :date_of_birth, :birthday, :email, :email_verified, :phone, :extension, :room,
    :job_title, :is_teacher, :active, :provisional, :house_code, :created_by, { divisions: [] }
  ].freeze

  rescue_from ActiveRecord::ConnectionNotEstablished do |e|
    render json: { error: "Could not connect to PostgreSQL: #{e.message}" }, status: :service_unavailable
  end

  rescue_from ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey, ActiveRecord::CheckViolation do |e|
    render json: { errors: [ e.cause&.message&.lines&.first&.strip || e.message ] }, status: :unprocessable_content
  end

  def index
    render json: Staff.order(:full_name)
  end

  def create
    staff = Staff.new(staff_params)

    if staff.save
      render json: staff, status: :created
    else
      render json: { errors: staff.errors.full_messages }, status: :unprocessable_content
    end
  end

  private
    def staff_params
      params.permit(PERMITTED_ATTRIBUTES)
    end
end
