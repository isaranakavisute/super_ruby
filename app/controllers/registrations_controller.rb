class RegistrationsController < ApplicationController
  # Adds a new account (myuser / mypassword) to the user_password table in PostgreSQL,
  # which is what the login page checks.
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to register_path, alert: "Try again later." }

  rescue_from ActiveRecord::ConnectionNotEstablished do
    @account ||= UserPassword.new
    flash.now[:alert] = "Could not reach the user database. Please try again later."
    render :new, status: :service_unavailable
  end

  def new
    @account = UserPassword.new
  end

  def create
    @account = UserPassword.new(
      myuser: params[:username],
      mypassword: params[:password],
      mypassword_confirmation: params[:password_confirmation]
    )

    if @account.save
      # Back to the login page to sign in with the new account (username already filled in)
      redirect_to login_path(username: @account.myuser), notice: "Registration successful. Please sign in."
    else
      # 422 status is required for Turbo to display a re-rendered form
      render :new, status: :unprocessable_content
    end
  end
end
