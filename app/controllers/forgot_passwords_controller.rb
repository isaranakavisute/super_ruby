# "Forgot password?" on the login page. The user enters their username, and the request is shown
# to the admin in the Admin Panel, who resets the password and tells the user the new one.
class ForgotPasswordsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to forgot_password_path, alert: "Too many requests. Please try again later." }

  # Same message whether or not the username exists, so this page can't be used to find out which usernames are registered
  SENT_MESSAGE = "Your request has been sent to the admin. The admin will reset your password and let you know the new one.".freeze

  def new
  end

  def create
    username = params[:username].to_s.strip
    if username.empty?
      @error = "Please enter your username"
      return render :new, status: :unprocessable_content
    end

    # Usernames are unique regardless of case, so "Bob" finds bob's account
    if account = UserPassword.where("LOWER(myuser) = LOWER(?)", username).first
      PasswordResetRequest.submit(account.myuser, ip_address: request.remote_ip)
    end

    redirect_to login_path, notice: SENT_MESSAGE
  rescue ActiveRecord::ConnectionNotEstablished
    @error = "Could not reach the user database. Please try again later."
    render :new, status: :service_unavailable
  end
end
