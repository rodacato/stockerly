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

  # --- Authenticated Zone ---
  get "onboarding/step1", to: "onboarding#step1"
  get "onboarding/step2", to: "onboarding#step2"
  get "onboarding/step3", to: "onboarding#step3"

  get "dashboard", to: "dashboard#show"
  get "market",    to: "market#index"

  resource  :portfolio, only: [:show]
  resources :alerts,    only: [:index, :create, :update, :destroy]
  resources :earnings,  only: [:index]
  resource  :profile,   only: [:show, :update]

  # --- Admin Zone ---
  namespace :admin do
    resources :assets, only: [:index]
    resources :logs,   only: [:index]
    resources :users,  only: [:index]
  end
end
