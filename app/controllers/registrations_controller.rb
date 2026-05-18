class RegistrationsController < ApplicationController
  layout "public"

  rate_limit to: 5, within: 1.minute, only: :create
  before_action :redirect_if_logged_in, only: [ :new, :create ]
  before_action :require_registration_open, only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    if honeypot_filled?
      redirect_to root_path
      return
    end

    result = Identity::UseCases::Register.call(params: registration_params_with_consent)

    case result
    in Dry::Monads::Success(user)
      start_session(user)
      redirect_to dashboard_path, notice: "Welcome to Stockerly, #{user.full_name}!"
    in Dry::Monads::Failure[ :validation, errors ]
      @user = User.new(registration_params.except(:invite_code, :consents_data_processing))
      @consents_data_processing = registration_params[:consents_data_processing] == "1"
      errors.each { |field, msgs| msgs.each { |msg| @user.errors.add(field, msg) } }
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.permit(:full_name, :email, :password, :password_confirmation, :invite_code, :consents_data_processing)
  end

  # Checkbox arrives as "1" when checked, missing/nil otherwise. Coerce to a
  # real boolean so the contract's `value(:bool)` rule sees true/false
  # (ActiveModel::Type::Boolean#cast returns nil for nil — explicitly fold
  # nil to false so an unchecked checkbox is treated as denial, not as a
  # missing field).
  def registration_params_with_consent
    raw = registration_params.to_h
    raw["consents_data_processing"] = ActiveModel::Type::Boolean.new.cast(raw["consents_data_processing"]) == true
    raw
  end

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end

  def require_registration_open
    return if SiteConfig.registration_open?

    redirect_to login_path, alert: "Registration is currently closed."
  end

  def honeypot_filled?
    params[:website].present?
  end
end
