Rails.application.routes.draw do
  # Login page (index), log in (create) and log out (destroy), all at /login
  get    "login" => "sessions#index", as: :login
  post   "login" => "sessions#create"
  delete "login" => "sessions#destroy"

  # Registration page (new) and create the account (create), both at /register
  get    "register" => "registrations#new", as: :register
  post   "register" => "registrations#create"

  # Admin Panel: list of all user_password accounts, shown to the "admin" user after login
  get "admin" => "admin#index", as: :admin_panel
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
