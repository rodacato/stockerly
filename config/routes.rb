Rails.application.routes.draw do
  # --- Health Check ---
  get "up" => "rails/health#show", as: :rails_health_check

  # --- Public Pages ---
  root "pages#landing"
  get "open-source", to: "pages#open_source", as: :open_source
  get "trends",      to: "trends#index"

  # --- Legal ---
  get "privacy",         to: "legal#privacy"
  get "terms",           to: "legal#terms"
  get "risk-disclosure", to: "legal#risk_disclosure", as: :risk_disclosure

  # --- Authentication ---
  get    "login",    to: "sessions#new"
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy"
  get    "register", to: "registrations#new"
  post   "register", to: "registrations#create"

  # --- Password Reset ---
  get   "forgot-password",       to: "password_resets#new",    as: :forgot_password
  post  "forgot-password",       to: "password_resets#create"
  get   "reset-password/:token", to: "password_resets#edit",   as: :reset_password
  patch "reset-password/:token", to: "password_resets#update"

  # --- Email Verification ---
  get  "verify-email/:token", to: "email_verifications#show",  as: :verify_email
  post "resend-verification", to: "email_verifications#create", as: :resend_verification

  # --- Authenticated Zone ---
  get  "onboarding/step1", to: "onboarding#step1"
  get  "onboarding/step2", to: "onboarding#step2"
  post "onboarding/complete", to: "onboarding#complete", as: :complete_onboarding
  post "onboarding/skip",     to: "onboarding#skip",     as: :skip_onboarding
  get  "onboarding/step3", to: "onboarding#step3"

  get "news",      to: "news#index"
  get "dashboard", to: "dashboard#show"
  get "market",          to: "market#index"
  get "market/:symbol",  to: "market#show", as: :market_asset
  get "search",    to: "search#index"

  resource  :portfolio, only: [ :show ]
  resources :alerts, only: [ :index, :create, :update, :destroy ] do
    member { patch :toggle }
  end
  resources :trades,    only: [ :index, :create, :edit, :update, :destroy ]
  resources :earnings,  only: [ :index, :show ]
  resources :watchlist_items, only: [ :create, :destroy ]
  resources :notifications, only: [ :index ] do
    member { patch :mark_as_read }
    collection { patch :mark_all_read }
  end
  resource :profile,   only: [ :show, :update ]
  patch "profile/password",    to: "profiles#change_password",    as: :change_password
  patch "profile/preferences", to: "profiles#update_preferences", as: :update_preferences

  # --- Admin Zone ---
  namespace :admin do
    root "dashboard#show"
    post "refresh_fx_rates", to: "dashboard#refresh_fx_rates"
    post "trigger_data_source/:key", to: "dashboard#trigger_data_source", as: :trigger_data_source

    resources :assets, only: [ :index, :create, :destroy ] do
      member do
        patch :toggle_status
        post  :trigger_sync
      end
      collection { post :trigger_sync_all }
    end
    resources :integrations, only: [ :create ] do
      member { post :refresh_sync }
    end
    resources :logs, only: [ :index ] do
      collection { get :export_csv }
    end
    resources :users, only: [ :index ] do
      member { patch :suspend }
    end
  end
end
