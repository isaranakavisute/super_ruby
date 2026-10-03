# "Continue with Google / Facebook" (login page) and "Connect" (Account page).
#   1. start / connect: check the CSRF token (Rails does), then hand OmniAuth a one-time pass and send the browser to /auth/<provider>
#   2. Google / Facebook ask the user to sign in and approve, then send them back to callback
#   3. callback: find or create the account, then 2FA (TwoFactorController) like a password sign-in
class SocialLoginsController < ApplicationController
  allow_unauthenticated_access only: %i[ start callback failure ]
  before_action :require_enabled_provider, only: %i[ start connect ]
  rate_limit to: 10, within: 3.minutes, only: :start, with: -> { redirect_to login_path, alert: "Try again later." }

  rescue_from ActiveRecord::ConnectionNotEstablished do
    redirect_to login_path, alert: "Could not reach the user database. Please try again later."
  end

  # POST /login/social/:provider. No CAPTCHA: Google / Facebook protect their own sign-in pages from bots,
  # and 2FA is still required afterwards.
  def start
    SocialLogin.grant_pass(session, params[:provider], "login")
    redirect_to "/auth/#{params[:provider]}"
  end

  # POST /account/connections/:provider (signed in already, so no CAPTCHA)
  def connect
    SocialLogin.grant_pass(session, params[:provider], "link")
    redirect_to "/auth/#{params[:provider]}"
  end

  # GET /auth/:provider/callback
  def callback
    auth = request.env["omniauth.auth"]
    intent = session.delete(:social_login_intent)
    return redirect_to login_path, alert: "Sign-in with #{provider_label} didn't complete. Please try again." unless auth && intent

    intent == "link" ? link(auth) : sign_in(auth)
  end

  # GET /auth/failure?message=...&strategy=... (cancelled at Google / Facebook, or an invalid request)
  def failure
    reason = params[:message] == "access_denied" ? "was cancelled" : "didn't work"
    label = SocialLogin::PROVIDERS.key?(params[:strategy]) ? SocialLogin.label(params[:strategy]) : "Google / Facebook"
    redirect_to login_path, alert: "Sign-in with #{label} #{reason}. Please try again, or sign in with your password."
  end

  private
    def sign_in(auth)
      identity = UserIdentity.find_by(provider: auth.provider, uid: auth.uid)
      account = identity&.user_password || create_account_for(auth)

      start_two_factor_for account
    end

    def create_account_for(auth)
      UserPassword.transaction do
        account = UserPassword.create_for_social_login!(email: auth.info.email, name: auth.info.name)
        account.identities.create!(identity_attributes(auth))
        account
      end
    end

    def link(auth)
      return redirect_to login_path, alert: "Please sign in first." unless authenticated?

      account = Current.user.user_password_account
      existing = UserIdentity.find_by(provider: auth.provider, uid: auth.uid)

      if existing && existing.user_password_id != account.id
        redirect_to account_path, alert: "That #{provider_label} account is already connected to another user."
      elsif existing
        redirect_to account_path, notice: "#{provider_label} is already connected."
      else
        identity = account.identities.create(identity_attributes(auth))
        if identity.persisted?
          redirect_to account_path, notice: "#{provider_label} is now connected. You can use it to sign in."
        else
          redirect_to account_path, alert: identity.errors.full_messages.to_sentence
        end
      end
    end

    def identity_attributes(auth)
      { provider: auth.provider, uid: auth.uid, email: auth.info.email, name: auth.info.name }
    end

    def require_enabled_provider
      return if SocialLogin.enabled?(params[:provider])

      redirect_to login_path, alert: "Sign-in with that service isn't set up."
    end

    def provider_label
      SocialLogin::PROVIDERS.key?(params[:provider]) ? SocialLogin.label(params[:provider]) : "Google / Facebook"
    end
end
