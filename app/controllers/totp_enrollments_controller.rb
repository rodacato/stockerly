class TotpEnrollmentsController < AuthenticatedController
  # The wizard's third step links here (D52), and an account mid-wizard is not
  # `onboarded?` yet — without this the step would bounce the reader back to
  # step 1 of the wizard it lives inside.
  skip_before_action :redirect_to_onboarding

  rate_limit to: 10, within: 1.minute, only: :create

  # First, so the guards below can redirect to it.
  before_action :set_return_path
  before_action :redirect_if_enrolled, only: [ :new, :create ]
  before_action :require_enrolled, only: :regenerate

  # Shown once. Reloading after the codes leave the session sends the reader to
  # Ajustes, which is where a fresh set can be minted — the honest answer, since
  # these cannot be shown again.
  def show
    @codes = session.delete(:fresh_recovery_codes)
    redirect_to @return_path, alert: t(".ya_no_disponibles") if @codes.blank?
  end
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


  def regenerate
    session[:fresh_recovery_codes] = Identity::UseCases::RegenerateRecoveryCodes.call(user: current_user)
    redirect_to recovery_codes_path
  end

  private

  # Enrolment is reachable from two places and has to hand the reader back to
  # the one they came from: Ajustes, or the wizard they are still inside.
  def set_return_path
    @return_path = current_user.onboarded? ? settings_path : onboarding_complete_path
  end

  def redirect_if_enrolled
    redirect_to @return_path, notice: t("totp_enrollments.new.ya_activa") if current_user.otp_enrolled?
  end

  def require_enrolled
    redirect_to totp_enrollment_path unless current_user.otp_enrolled?
  end
end
