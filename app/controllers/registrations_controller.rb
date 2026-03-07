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

    result = Identity::UseCases::Register.call(params: registration_params.to_h)

    case result
    in Dry::Monads::Success(user)
      start_session(user)
      redirect_to dashboard_path, notice: "Welcome to Stockerly, #{user.full_name}!"
    in Dry::Monads::Failure[ :validation, errors ]
      @user = User.new(registration_params)
      errors.each { |field, msgs| msgs.each { |msg| @user.errors.add(field, msg) } }
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.permit(:full_name, :email, :password, :password_confirmation)
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
