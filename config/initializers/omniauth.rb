# "Continue with Google / Facebook" on the login page (see app/models/social_login.rb).
# Keys are read from .env.<environment>; a provider is only offered once both of its keys are set.
#   Google:   GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET   (console.cloud.google.com > APIs & Services > Credentials)
#   Facebook: FACEBOOK_APP_ID, FACEBOOK_APP_SECRET     (developers.facebook.com > My Apps)
# Redirect URIs to register with each provider:
#   http://localhost:3000/auth/<provider>/callback                 (development)
#   https://api.167-71-205-74.sslip.io/auth/<provider>/callback    (production)
# where <provider> is google_oauth2 or facebook.
# (Same rule as SocialLogin.enabled?; app/ classes can't be loaded while Rails is starting.)
social_login_enabled = ->(*keys) { Rails.env.test? || keys.all? { |key| ENV[key].present? } }

Rails.application.config.middleware.use OmniAuth::Builder do
  if social_login_enabled.call("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET")
    provider :google_oauth2, ENV.fetch("GOOGLE_CLIENT_ID", "test"), ENV.fetch("GOOGLE_CLIENT_SECRET", "test"),
             scope: "email,profile", prompt: "select_account"
  end

  if social_login_enabled.call("FACEBOOK_APP_ID", "FACEBOOK_APP_SECRET")
    provider :facebook, ENV.fetch("FACEBOOK_APP_ID", "test"), ENV.fetch("FACEBOOK_APP_SECRET", "test"),
             scope: "email,public_profile", info_fields: "email,name"
  end
end

# Requests reach /auth/<provider> by redirect from SocialLoginsController, which has already checked the
# CSRF token. The one-time pass it hands over is checked here instead of a form token.
OmniAuth.config.allowed_request_methods = %i[ get ]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.request_validation_phase = ->(env) { SocialLogin.validate_request!(env) }
OmniAuth.config.logger = Rails.logger
# Failures (cancelled at Google, invalid request, ...) go to /auth/failure in every environment.
# By default OmniAuth shows an error page in development instead.
OmniAuth.config.failure_raise_out_environments = []
