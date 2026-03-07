Rails.application.routes.draw do
  # --- Health Checks ---
  get "up", to: "rails/health#show", as: :rails_health_check  # Kamal deploy probe (always 200 if Rails boots)
  get "health", to: "health#show"                              # Detailed sync-freshness monitor

  # --- First-Boot Setup ---
  get  "setup", to: "setup#new"
  post "setup", to: "setup#create"

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
  get "dashboard",           to: "dashboard#show"
  get "dashboard/news_feed", to: "dashboard#news_feed", as: :dashboard_news_feed
  get "dashboard/trending",  to: "dashboard#trending",  as: :dashboard_trending
  get "market",                        to: "market#index"
  get "market/:symbol",                to: "market#show",           as: :market_asset
  get "market/:symbol/earnings_tab",   to: "market#earnings_tab",   as: :market_asset_earnings_tab
  get "market/:symbol/statements_tab", to: "market#statements_tab", as: :market_asset_statements_tab
  get "search",    to: "search#index"

  resource  :portfolio, only: [ :show ]
  resources :alerts, only: [ :index, :create, :update, :destroy ] do
    member { patch :toggle }
  end
  resources :positions, only: [ :update ]
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
  constraints ->(req) { (id = req.session[:user_id]) && User.find_by(id: id)&.admin? } do
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end

  namespace :admin do
    root "dashboard#show"
    post "refresh_fx_rates", to: "dashboard#refresh_fx_rates"
    post "trigger_data_source/:key", to: "dashboard#trigger_data_source", as: :trigger_data_source

    # Admin Onboarding Wizard
    get   "onboarding/integrations", to: "onboarding#integrations", as: :onboarding_integrations
    patch "onboarding/integrations", to: "onboarding#save_integrations", as: :onboarding_save_integrations
    get   "onboarding/assets",       to: "onboarding#assets", as: :onboarding_assets
    post  "onboarding/assets",       to: "onboarding#save_assets", as: :onboarding_save_assets
    get   "onboarding/complete",     to: "onboarding#complete", as: :onboarding_complete
    post  "onboarding/launch",       to: "onboarding#launch", as: :onboarding_launch

    resources :assets, only: [ :index, :create, :update, :destroy ] do
      member do
        patch :toggle_status
        post  :trigger_sync
      end
      collection do
        post :trigger_sync_all
        get  :search
      end
    end
    resources :integrations, only: [ :index, :create, :update, :destroy ] do
      member { post :refresh_sync }
      resources :pool_keys, only: [ :create, :destroy ], controller: "pool_keys" do
        member { patch :toggle }
      end
    end
    resources :logs, only: [ :index ] do
      collection { get :export_csv }
    end
    resources :users, only: [ :index, :destroy ] do
      member do
        patch :suspend
        patch :reactivate
      end
    end
    resource :settings, only: [ :show, :update ]
  end
end
