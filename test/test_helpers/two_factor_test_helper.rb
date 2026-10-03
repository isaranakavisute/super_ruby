module TwoFactorTestHelper
  # Every test account that has 2FA turned on uses this secret, so tests can calculate the current code
  OTP_SECRET = ROTP::Base32.random.freeze

  # Turns on 2FA for username, as if they had scanned the QR code. Returns their recovery codes.
  def enable_two_factor_for(username)
    UserPassword.find_by!(myuser: username).enable_two_factor!(OTP_SECRET)
  end

  # The 6-digit code the authenticator app would show now
  def otp_code(secret = OTP_SECRET)
    ROTP::TOTP.new(secret).now
  end
end

module TwoFactorIntegrationTestHelper
  # Signs in through the real login form and the 2FA step (turning 2FA on first if needed)
  def sign_in_with_two_factor(username, password)
    enable_two_factor_for(username) unless UserPassword.find_by!(myuser: username).two_factor_enabled?
    post_login(username, password)
    post two_factor_path, params: { code: otp_code }
  end
end

ActiveSupport.on_load(:active_support_test_case) { include TwoFactorTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include TwoFactorIntegrationTestHelper }
