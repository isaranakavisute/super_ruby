Rails.application.routes.draw do
  # Login page (index), log in (create) and log out (destroy), all at /login
  get    "login" => "sessions#index", as: :login
  post   "login" => "sessions#create"
  delete "login" => "sessions#destroy"
  get    "login/captcha" => "sessions#captcha", as: :login_captcha

  # "Continue with Google / Facebook" (SocialLoginsController). /auth/:provider itself is handled by OmniAuth.
  constraints provider: /google_oauth2|facebook/ do
    post "login/social/:provider" => "social_logins#start", as: :social_login
    get  "auth/:provider/callback" => "social_logins#callback"
    post "account/connections/:provider" => "social_logins#connect", as: :connect_social_login
  end
  get "auth/failure" => "social_logins#failure"

  # Account page: connected Google / Facebook accounts
  get    "account" => "accounts#show", as: :account
  delete "account/connections/:id" => "accounts#disconnect", as: :disconnect_social_login

  # Two-factor authentication, the second step of signing in (after the password)
  get  "two_factor" => "two_factor#verify", as: :two_factor
  post "two_factor" => "two_factor#check"
  get  "two_factor/setup" => "two_factor#setup", as: :two_factor_setup
  post "two_factor/setup" => "two_factor#enable"
  get  "two_factor/recovery_codes" => "two_factor#recovery_codes", as: :two_factor_recovery_codes

  # Registration page (new) and create the account (create), both at /register
  get    "register" => "registrations#new", as: :register
  post   "register" => "registrations#create"

  # "Forgot password?" page (new) and send the request to the admin (create), both at /forgot_password
  get    "forgot_password" => "forgot_passwords#new", as: :forgot_password
  post   "forgot_password" => "forgot_passwords#create"

  # Admin Panel: list of all user_password accounts, shown to the "admin" user after login
  get "admin" => "admin#index", as: :admin_panel
  get "admin/products" => "admin#products", as: :admin_products
  post "admin/users/:id/reset_password" => "admin#reset_password", as: :admin_reset_password
  patch "admin/users/:id" => "admin#update_user", as: :admin_user
  post "admin/users/:id/reset_two_factor" => "admin#reset_two_factor", as: :admin_reset_two_factor
  get "admin/reset_requests" => "admin#reset_requests", as: :admin_reset_requests
  post "admin/reset_requests/:id/resolve" => "admin#resolve_reset_request", as: :admin_resolve_reset_request
  delete "admin/reset_requests/:id" => "admin#dismiss_reset_request", as: :admin_dismiss_reset_request
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "test" => "current_time#show"
  get "show_tables" => "tables#index"
  get "staff" => "staff#index"
  post "add_staff" => "staff#create"
  get "user" => "user_passwords#index"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "hello" => "hello#index"

  # Defines the root path route ("/"): the shop, shown after logging in
  root "products#index"
end
