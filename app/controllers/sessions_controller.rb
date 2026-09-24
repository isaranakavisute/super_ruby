class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ index create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }

  def index
  end

  # Checks the username and password against myuser / mypassword in the user_password table
  # of the PostgreSQL database (see .env.<environment>).
  def create
    if account = UserPassword.authenticate(params[:username], params[:password])
      start_new_session_for User.for_user_password(account)
      redirect_to after_authentication_url
    else
      # Re-show the form (keeping the username) with the error under the password field.
      # 422 status is required for Turbo to display a re-rendered form.
      @error = "Password is incorrect"
      render :index, status: :unprocessable_content
    end
  rescue ActiveRecord::ConnectionNotEstablished
    @error = "Could not reach the user database. Please try again later."
    render :index, status: :service_unavailable
  end

  def destroy
    terminate_session
    redirect_to login_path, status: :see_other
  end
end
