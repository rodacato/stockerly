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
  get  "login",    to: "sessions#new"
  get  "register", to: "registrations#new"
end
