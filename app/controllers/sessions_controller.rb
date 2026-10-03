class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ index create captcha ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }
  rate_limit to: 30, within: 1.minute, only: :captcha, with: -> { head :too_many_requests }

  def index
  end

  # GET /login/captcha: a new CAPTCHA image. Every load (including "New image") replaces the
  # previous challenge, so the answer always matches the image the user is looking at.
  def captcha
    LoginCaptcha.where(id: session[:login_captcha_id]).delete_all if session[:login_captcha_id]
    challenge = LoginCaptcha.issue!
    session[:login_captcha_id] = challenge.id

    response.headers["Cache-Control"] = "no-store"
    send_data challenge.to_png, type: "image/png", disposition: "inline"
  rescue ActiveRecord::ConnectionNotEstablished
    head :service_unavailable
  end

  # Checks the CAPTCHA first, then the username and password against myuser / mypassword in the
  # user_password table of the PostgreSQL database (see .env.<environment>).
  def create
    # Each CAPTCHA works once, so a bot has to solve a new one for every password it tries
    unless LoginCaptcha.solve(session.delete(:login_captcha_id), params[:captcha])
      @captcha_error = "The characters didn't match the image. Please type the characters in the new image."
      return render :index, status: :unprocessable_content
    end

    if account = UserPassword.authenticate(params[:username], params[:password])
      start_two_factor_for account
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
