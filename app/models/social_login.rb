# "Continue with Google / Facebook". OmniAuth (config/initializers/omniauth.rb) talks to the providers;
# this module holds the provider list and the one-time pass that lets a sign-in start.
#
# A sign-in only starts after SocialLoginsController has checked the form's CSRF token. It then puts
# a pass in the session and redirects to /auth/<provider>.
# OmniAuth calls validate_request! first, which accepts the request only with a fresh, matching pass,
# so another website can't start a Google/Facebook sign-in for our users.
module SocialLogin
  PROVIDERS = {
    "google_oauth2" => { label: "Google", keys: %w[ GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET ] },
    "facebook" => { label: "Facebook", keys: %w[ FACEBOOK_APP_ID FACEBOOK_APP_SECRET ] }
  }.freeze

  PASS_LIFETIME = 2.minutes

  class InvalidPass < OmniAuth::AuthenticityError; end

  module_function

  def label(provider)
    PROVIDERS.fetch(provider.to_s)[:label]
  end

  # Providers whose keys are set in .env.<environment> (tests use dummy keys and OmniAuth's test mode)
  def enabled_providers
    PROVIDERS.keys.select { |provider| Rails.env.test? || PROVIDERS[provider][:keys].all? { |key| ENV[key].present? } }
  end

  def enabled?(provider)
    enabled_providers.include?(provider.to_s)
  end

  # intent: "login" (from the login page) or "link" (from the Account page, while signed in)
  def grant_pass(session, provider, intent)
    session[:social_login_pass] = { "provider" => provider.to_s, "intent" => intent, "expires_at" => PASS_LIFETIME.from_now.to_i }
  end

  # OmniAuth request_validation_phase. Uses up the pass and remembers its intent for the callback.
  def validate_request!(env)
    session = env["rack.session"]
    pass = session.delete("social_login_pass") || {}
    provider = env["omniauth.strategy"].name.to_s

    unless pass["provider"] == provider && pass["expires_at"].to_i >= Time.current.to_i
      raise InvalidPass, "Sign-in with #{provider} must start from the login or Account page"
    end

    session["social_login_intent"] = pass["intent"]
  end
end
