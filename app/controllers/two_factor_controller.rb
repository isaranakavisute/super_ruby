# Second step of signing in, after SessionsController#create has checked the password.
# Everyone must use two-factor authentication with an authenticator app (e.g. Microsoft Authenticator):
#   - not set up yet: setup → scan the QR code, enter a code to confirm → recovery codes
#   - already set up: verify → enter the 6-digit code (or a recovery code)
class TwoFactorController < ApplicationController
  allow_unauthenticated_access except: :recovery_codes
  before_action :require_pending_account, except: :recovery_codes
  rate_limit to: 10, within: 3.minutes, only: %i[ check enable ],
             with: -> { redirect_to login_path, alert: "Too many attempts. Please sign in again later." }

  rescue_from ActiveRecord::ConnectionNotEstablished do
    redirect_to login_path, alert: "Could not reach the user database. Please try again later."
  end

  # GET /two_factor
  def verify
    redirect_to two_factor_setup_path unless @account.two_factor_enabled?
  end

  # POST /two_factor
  def check
    return redirect_to two_factor_setup_path unless @account.two_factor_enabled?

    code = params[:code].to_s.strip
    if @account.verify_otp(code)
      complete_sign_in
    elsif @account.use_recovery_code(code)
      complete_sign_in notice: "You signed in with a recovery code. #{helpers.pluralize(@account.recovery_codes_left, "recovery code")} left."
    else
      @error = if @account.otp_already_used?(code)
        "That code has already been used. Wait for the next code in your app (they change every 30 seconds), then enter it."
      else
        "That code is not correct. Check the code in your authenticator app and try again."
      end
      render :verify, status: :unprocessable_content
    end
  end

  # GET /two_factor/setup: QR code for the authenticator app. The secret is kept in the
  # session until the user proves the scan worked, so an abandoned setup changes nothing.
  def setup
    return redirect_to two_factor_path if @account.two_factor_enabled?

    @secret = (session[:pending_two_factor]["secret"] ||= ROTP::Base32.random)
    @qr_svg = RQRCode::QRCode.new(UserPassword.otp_provisioning_uri(@secret, @account.myuser))
                            .as_svg(module_size: 5, standalone: true, use_path: true, viewbox: true)
  end

  # POST /two_factor/setup
  def enable
    return redirect_to two_factor_path if @account.two_factor_enabled?

    secret = session[:pending_two_factor]["secret"]
    if secret && UserPassword.valid_otp?(secret, params[:code])
      session[:new_recovery_codes] = @account.enable_two_factor!(secret)
      @account.verify_otp(params[:code]) # mark this code as used
      complete_sign_in redirect: two_factor_recovery_codes_path
    else
      @error = "That code is not correct. Make sure you scanned this QR code, then enter the code shown in the app."
      setup
      render :setup, status: :unprocessable_content
    end
  end

  # GET /two_factor/recovery_codes: shown once, straight after setup
  def recovery_codes
    @codes = session.delete(:new_recovery_codes)
    @continue_path = continue_path
    redirect_to @continue_path unless @codes
  end

  private
    def require_pending_account
      pending = session[:pending_two_factor]
      if pending.nil? || pending["expires_at"].to_i < Time.current.to_i
        session.delete(:pending_two_factor)
        return redirect_to login_path, alert: "Please sign in again."
      end

      @account = UserPassword.find_by(id: pending["account_id"])
      redirect_to login_path, alert: "Please sign in again." unless @account
    end

    # Both steps passed: start the real session. The admin always goes to the Admin Panel;
    # everyone else to the page they asked for (or the shop).
    def complete_sign_in(notice: nil, redirect: nil)
      session.delete(:pending_two_factor)
      user = User.for_user_password(@account)
      start_new_session_for user

      redirect_to redirect || continue_path, notice: notice
    end

    def continue_path
      return_to = session.delete(:return_to_after_authenticating)
      Current.user&.admin? ? admin_panel_path : (return_to.presence || root_path)
    end
end
