Rails.application.routes.draw do
  # --- Health Checks ---
  get "up", to: "rails/health#show", as: :rails_health_check  # Kamal deploy probe (always 200 if Rails boots)
  get "health", to: "health#show"                              # Detailed sync-freshness monitor

  # --- First-Boot Setup ---
  get  "setup", to: "setup#new"
  post "setup", to: "setup#create"

  # --- Root ---
  # No public landing: the project is a closed beta, not a marketing funnel.
  # Anyone reaching `/` is bounced to `/login` (which redirects authenticated
  # users to `/dashboard`). Use 302 instead of the Rails default 301 so browsers
  # don't aggressively cache the redirect — we may re-route `/` later.
  root to: redirect("/login", status: 302)

  # --- Legal ---
  get "privacy",         to: "legal#privacy"
  get "terms",           to: "legal#terms"
  get "risk-disclosure", to: "legal#risk_disclosure", as: :risk_disclosure

  # --- Authentication ---
  get    "login",    to: "sessions#new"
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy"

  # --- Password Reset ---
  get   "forgot-password",       to: "password_resets#new",    as: :forgot_password
  post  "forgot-password",       to: "password_resets#create"
  get   "reset-password/:token", to: "password_resets#edit",   as: :reset_password
  patch "reset-password/:token", to: "password_resets#update"

  # --- Authenticated Zone ---
  # The setup wizard (D5: one account, so no admin zone). It ends at /welcome,
  # which is the step that marks the user onboarded (D30).
  get   "onboarding/integrations", to: "onboarding#integrations", as: :onboarding_integrations
  patch "onboarding/integrations", to: "onboarding#save_integrations", as: :onboarding_save_integrations
  get   "onboarding/assets",       to: "onboarding#assets", as: :onboarding_assets
  post  "onboarding/assets",       to: "onboarding#save_assets", as: :onboarding_save_assets
  get   "onboarding/complete",     to: "onboarding#complete", as: :onboarding_complete
  post  "onboarding/launch",       to: "onboarding#launch", as: :onboarding_launch

  get  "welcome",     to: "welcome#show",     as: :welcome
  post "welcome",     to: "welcome#complete", as: :complete_welcome
  get  "help",        to: "help#show",        as: :help
  get  "report-bug",  to: "bug_reports#new",  as: :new_bug_report
  post "report-bug",  to: "bug_reports#create", as: :bug_reports

  get "news",      to: "news#index"
  get "dashboard",           to: "dashboard#show"
  get "market",                        to: "market#index"
  get "market/:symbol",                to: "market#show",           as: :market_asset
  get "market/:symbol/earnings_tab",   to: "market#earnings_tab",   as: :market_asset_earnings_tab
  get "market/:symbol/statements_tab", to: "market#statements_tab", as: :market_asset_statements_tab
  get "search",    to: "search#index"

  # Propshaft owns the /assets prefix. It lets the exact path /assets through to
  # the router, but swallows anything nested under it — /assets/tracked is
  # recognised by the router and still 404s. Sub-screens of Activos therefore
  # live at their own top-level paths.
  get   "assets",                 to: "assets#index"
  get   "tracked",                to: "assets#tracked",     as: :tracked_assets
  get   "fx_rate",                to: "fx_rates#show"
  patch "tracked/:id/toggle_sync", to: "assets#toggle_sync", as: :toggle_sync_asset
  resource  :portfolio, only: [ :show ]
  resources :alerts, only: [ :index, :new, :create, :update, :destroy ] do
    member { patch :toggle }
  end
  resources :positions, only: [ :index, :update ]
  resources :trades,    only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member { get :confirm_destroy }
  end
  resources :earnings,  only: [ :index, :show ]
  resources :watchlist_items, only: [ :create, :destroy ]
  resources :notifications, only: [ :index ] do
    member { patch :mark_as_read }
    collection do
      patch  :mark_all_read
      delete :destroy_read
    end
  end
  resource :settings,  only: [ :show ]
  resource :profile,   only: [ :show, :update ]
  patch  "profile/password",    to: "profiles#change_password",    as: :change_password
  patch  "profile/preferences", to: "profiles#update_preferences", as: :update_preferences
  patch  "profile/currency",    to: "profiles#update_currency",    as: :update_currency

  # --- Admin Zone ---
  constraints ->(req) { (id = req.session[:user_id]) && User.find_by(id: id)&.admin? } do
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end

  namespace :admin do
    root "dashboard#show"
    post "refresh_fx_rates", to: "dashboard#refresh_fx_rates"
    post "trigger_data_source/:key", to: "dashboard#trigger_data_source", as: :trigger_data_source

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
    resource :settings, only: [ :show, :update ]
  end
end
