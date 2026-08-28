class TwoFactorController < ApplicationController
  layout "auth"

  # The window between the password and the code. Long enough to fetch a phone
  # from another room, short enough that a walked-away browser is not a
  # half-open door.
  PENDING_TIMEOUT = 10.minutes

  rate_limit to: 5, within: 1.minute, only: [ :create, :create_recovery ]

  before_action :require_pending_user

  def new; end

  def create
    verify(Identity::UseCases::VerifyTotpCode.call(user: @pending_user, code: params[:code])) do
      t("auth.flash.bienvenida", nombre: @pending_user.full_name)
    end
  end

  def new_recovery; end

  def create_recovery
    verify(Identity::UseCases::ConsumeRecoveryCode.call(user: @pending_user, code: params[:code]),
           render_on_failure: :new_recovery) do
      # Read after the consumption, never before it minus one.
      t("auth.flash.codigo_recuperacion_usado", count: @pending_user.unused_recovery_codes_count)
    end
  end

  private

  # The notice is a block because the recovery path's copy counts what is left
  # and must be read once the code has actually been spent.
  def verify(result, render_on_failure: :new)
    case result
    in Dry::Monads::Success(_)
      complete_login(yield)
    in Dry::Monads::Failure[ _, message ]
      EventBus.publish(Identity::Events::UserLoginFailed.new(email: @pending_user.email,
                                                             ip_address: request.remote_ip,
                                                             user_agent: request.user_agent.to_s))
      flash.now[:alert] = message
      render render_on_failure, status: :unprocessable_content
    end
  end

  # `start_session` resets the session, which drops the pending keys with it —
  # the half-authenticated state cannot outlive the login it belonged to.
  def complete_login(notice)
    user = @pending_user
    start_session(user)
    EventBus.publish(Identity::Events::UserLoggedIn.new(user_id: user.id,
                                                        ip_address: request.remote_ip,
                                                        user_agent: request.user_agent.to_s))
    redirect_to dashboard_path, notice: notice
  end

  # Nothing here reads `current_user`: the password step deliberately does not
  # set `session[:user_id]`, so an unfinished login has no identity anywhere in
  # the app. This is the only place that knows who is half-way in.
  def require_pending_user
    id = session[:pending_user_id]
    started = session[:pending_since]

    if id.blank? || started.blank? || Time.at(started.to_i) < PENDING_TIMEOUT.ago
      reset_session
      return redirect_to login_path, alert: t("auth.flash.verificacion_expirada")
    end

    @pending_user = User.find_by(id: id)
    return if @pending_user&.otp_enrolled?

    reset_session
    redirect_to login_path, alert: t("auth.flash.credenciales_invalidas")
  end
end
