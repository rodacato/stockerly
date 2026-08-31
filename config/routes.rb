Rails.application.routes.draw do
  # --- Health Checks ---
  get "up", to: "rails/health#show", as: :rails_health_check  # Kamal deploy probe (always 200 if Rails boots)
  get "health", to: "health#show"                              # Detailed sync-freshness monitor

  # --- First-Boot Setup ---
  get  "setup", to: "setup#new"
  post "setup", to: "setup#create"

  # --- PWA ---
  # Rails serves these, not `public/`: the static file server stamps everything
  # with a one-year max-age, which pinned installed apps to an old worker.
  get "manifest.json",     to: "pwa#manifest",       as: :pwa_manifest
  get "service-worker.js", to: "pwa#service_worker", as: :pwa_service_worker

  # --- Root ---
  # No public landing: the instance has one account, not an audience to convert.
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

  # The second factor. Reachable only with a pending login in the session —
  # the password step does not set `session[:user_id]`, so these are the only
  # routes a half-authenticated visitor can touch (ADR-018).
  get  "two-factor",    to: "two_factor#new",             as: :two_factor
  post "two-factor",    to: "two_factor#create"
  get  "recovery-code", to: "two_factor#new_recovery",    as: :recovery_code
  post "recovery-code", to: "two_factor#create_recovery"

  # Enrolment lives behind the session, not beside the login: turning the
  # second factor on is something an authenticated owner does.
  get  "two-factor/setup", to: "totp_enrollments#new",        as: :totp_enrollment
  post "two-factor/setup", to: "totp_enrollments#create"
  get  "two-factor/codes", to: "totp_enrollments#show",       as: :recovery_codes
  post "two-factor/codes", to: "totp_enrollments#regenerate", as: :regenerate_recovery_codes

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
  get   "onboarding/security",     to: "onboarding#security", as: :onboarding_security
  get   "onboarding/complete",     to: "onboarding#complete", as: :onboarding_complete
  post  "onboarding/launch",       to: "onboarding#launch", as: :onboarding_launch

  get  "welcome",     to: "welcome#show",     as: :welcome
  post "welcome",     to: "welcome#complete", as: :complete_welcome
  get  "help",        to: "help#show",        as: :help
  get  "report-bug",  to: "bug_reports#new",  as: :new_bug_report
  post "report-bug",  to: "bug_reports#create", as: :bug_reports

  get "dashboard",           to: "dashboard#show"
  # D31's disposability contract: zero tables, zero rows. Deleting Descubrir is
  # this line, one nav entry, one controller, one view folder and two YAMLs.
  get "discover",            to: "discover#show"
  # D31 deleted /market's listing, /news and /earnings: all three read the
  # instance's own catalogue, which is the bubble Descubrir exists to leave.
  # The asset detail below is a different screen and stays.
  get "market/:symbol",                to: "market#show",           as: :market_asset
  get "market/:symbol/earnings_tab",   to: "market#earnings_tab",   as: :market_asset_earnings_tab
  get "market/:symbol/statements_tab", to: "market#statements_tab", as: :market_asset_statements_tab
  # The fundamentals sync used to fire from the GET above (CKP-7). It is a
  # write, so it asks for a verb.
  post "market/:symbol/fundamentals",  to: "market#request_fundamentals", as: :market_asset_fundamentals

  # Propshaft owns the /assets prefix. It lets the exact path /assets through to
  # the router, but swallows anything nested under it — /assets/tracked is
  # recognised by the router and still 404s. Sub-screens of Activos therefore
  # live at their own top-level paths.
  get    "assets",                  to: "assets#index"
  get    "tracked",                 to: "assets#tracked",      as: :tracked_assets
  get    "fx_rate",                 to: "fx_rates#show"
  # Tracked absorbed the last of /admin/assets (D9): the catalogue is added
  # to and removed from here, not from an admin console. `search` is declared
  # before `:id` so a literal segment is not read as an identifier.
  get    "tracked/search",          to: "assets#search_ticker", as: :search_tickers
  post   "tracked",                 to: "assets#track",         as: :track_asset
  delete "tracked/:id",             to: "assets#untrack",       as: :untrack_asset
  patch  "tracked/:id/toggle_sync", to: "assets#toggle_sync",   as: :toggle_sync_asset
  patch  "tracked/:id/source_symbol", to: "assets#map_source_symbol", as: :map_source_symbol_asset
  resource  :portfolio, only: [ :show ]
  resources :alerts, only: [ :index, :new, :create, :update, :destroy ] do
    member { patch :toggle }
  end
  # Historial. `update` went with the four-tab table: `notes` and `labels` were
  # written by an endpoint no view ever posted to, and no artboard draws them.
  resources :positions, only: [ :index ]
  # Declared before `resources :trades` so /trades/import is never read as a
  # member route. Preview and commit are separate verbs on purpose: the preview
  # writes nothing, and confirming is its own deliberate act (#401).
  get  "trades/import",         to: "trade_imports#new",     as: :new_trade_import
  post "trades/import/preview", to: "trade_imports#preview", as: :preview_trade_import
  post "trades/import",         to: "trade_imports#create",  as: :trade_imports
  post "trades/import/tracked", to: "trade_imports#track_missing", as: :track_missing_trade_import

  # No `index` since D60 — Historial holds the trade log, and /trades had no
  # inbound link from anywhere in the app. The sheet and the inline row flows
  # stay.
  resources :trades, only: [ :new, :create, :edit, :update, :destroy ] do
    member { get :confirm_destroy }
  end
  resources :watchlist_items, only: [ :create, :destroy ]
  resources :notifications, only: [ :index ] do
    member { patch :mark_as_read }
    collection do
      patch  :mark_all_read
      delete :destroy_read
    end
  end
  resource :settings,  only: [ :show ] do
    delete "trading-data", to: "settings#destroy_trading_data", as: :trading_data
    delete "account",      to: "settings#destroy_account",      as: :account
  end
  resource :profile,   only: [ :show, :update ]
  patch  "profile/password",    to: "profiles#change_password",    as: :change_password
  patch  "profile/preferences", to: "profiles#update_preferences", as: :update_preferences

  post   "push-subscriptions", to: "push_subscriptions#create",  as: :push_subscriptions
  delete "push-subscriptions", to: "push_subscriptions#destroy"
  patch  "profile/currency",    to: "profiles#update_currency",    as: :update_currency

  # --- Admin Zone ---
  constraints ->(req) { (id = req.session[:user_id]) && User.find_by(id: id)&.admin? } do
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end

  namespace :admin do
    resources :integrations, only: [ :index, :create, :update, :destroy ] do
      member { post :refresh_sync }
    end
    resources :logs, only: [ :index ] do
      collection { get :export_csv }
    end
    # ADR-020: the instance's own error tracker, gated by the developer_mode
    # switch rather than by a separate zone.
    resources :errors, only: [ :index, :show, :destroy ]
    resource :settings, only: [ :show, :update ]
    # `refresh_fx_rates` used to be its own route; :fx_rates is a registered
    # source whose job_class is RefreshFxRatesJob, so the two collapse into one.
    post "trigger_data_source/:key", to: "settings#trigger_data_source", as: :trigger_data_source
  end
end
