class SessionsController < ApplicationController
  layout "auth"

  rate_limit to: 5, within: 1.minute, only: :create

  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new; end

  def create
    result = Identity::UseCases::Login.call(params: { email: params[:email], password: params[:password] })

    case result
    in Dry::Monads::Success(user) if user.otp_enrolled?
      # Deliberately NOT start_session: `current_user` reads session[:user_id],
      # so withholding it is what makes an unfinished login reach nothing. The
      # second factor is not a guard bolted onto an authenticated session — the
      # session does not exist yet (ADR-018).
      reset_session
      session[:pending_user_id] = user.id
      session[:pending_since] = Time.current.to_i
      redirect_to two_factor_path
    in Dry::Monads::Success(user)
      start_session(user)
      EventBus.publish(Identity::Events::UserLoggedIn.new(user_id: user.id, ip_address: request.remote_ip, user_agent: request.user_agent.to_s))
      redirect_to dashboard_path, notice: t("auth.flash.bienvenida", nombre: user.full_name)
    in Dry::Monads::Failure[ :invalid_credentials, message ]
      publish_login_failed
      flash.now[:alert] = message
      render :new, status: :unprocessable_content
    in Dry::Monads::Failure[ :validation, _ ]
      flash.now[:alert] = t("auth.flash.credenciales_invalidas")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("auth.flash.sesion_cerrada")
  end

  private

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end

  def publish_login_failed
    return unless params[:email].present?

    EventBus.publish(Identity::Events::UserLoginFailed.new(email: params[:email].to_s, ip_address: request.remote_ip, user_agent: request.user_agent.to_s))
  end
end
