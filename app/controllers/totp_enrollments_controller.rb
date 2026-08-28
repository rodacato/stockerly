class TotpEnrollmentsController < AuthenticatedController
  rate_limit to: 10, within: 1.minute, only: :create

  before_action :redirect_if_enrolled, only: [ :new, :create ]
  before_action :require_enrolled, only: :regenerate

  def new
    @enrollment = Identity::UseCases::BeginTotpEnrollment.call(user: current_user)
  end

  def create
    case Identity::UseCases::EnableTotp.call(user: current_user, code: params[:code])
    in Dry::Monads::Success(recovery_codes: codes)
      # The only moment the codes exist in the clear. They go in the session
      # rather than an ivar because the next screen is a redirect, and rather
      # than the database because storing them readable would undo the point
      # of hashing them.
      session[:fresh_recovery_codes] = codes
      redirect_to recovery_codes_path
    in Dry::Monads::Failure[ _, message ]
      @enrollment = Identity::UseCases::BeginTotpEnrollment.call(user: current_user)
      flash.now[:alert] = message
      render :new, status: :unprocessable_content
    end
  end

  # Shown once. Reloading after the codes leave the session sends the reader to
  # Ajustes, which is where a fresh set can be minted — the honest answer, since
  # these cannot be shown again.
  def show
    @codes = session.delete(:fresh_recovery_codes)
    redirect_to settings_path, alert: t(".ya_no_disponibles") if @codes.blank?
  end

  def regenerate
    session[:fresh_recovery_codes] = Identity::UseCases::RegenerateRecoveryCodes.call(user: current_user)
    redirect_to recovery_codes_path
  end

  private

  def redirect_if_enrolled
    redirect_to settings_path, notice: t("totp_enrollments.new.ya_activa") if current_user.otp_enrolled?
  end

  def require_enrolled
    redirect_to totp_enrollment_path unless current_user.otp_enrolled?
  end
end
