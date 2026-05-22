class PasswordResetsController < ApplicationController
  layout "public"

  rate_limit to: 3, within: 1.hour, only: :create

  before_action :find_user_by_token, only: [ :edit ]

  # GET /forgot-password — state 1: forgot form
  def new; end

  # POST /forgot-password — state 2: forgot-sent confirmation.
  # Renders a dedicated `sent` template (no flash-and-redirect) so the
  # user lands on a clear "revisa tu correo" page they can dwell on.
  # Privacy-preserving: same response regardless of whether the email
  # is registered (the UseCase already no-ops silently for unknown
  # emails) — never reveal whether an account exists.
  def create
    Identity::UseCases::RequestPasswordReset.call(params: { email: params[:email] })
    render :sent
  end

  # GET /reset-password/:token — state 3: reset form (or state 4 expired).
  # `find_user_by_token` renders `expired` instead of redirecting with a
  # flash when the token cannot be resolved, so the user gets an explicit
  # explanation page with a CTA back to /forgot-password.
  def edit; end

  # PATCH /reset-password/:token — state 5: reset-success on success,
  # back to the form (with errors) on validation failure, expired page
  # if the token died between GET and PATCH.
  def update
    result = Identity::UseCases::ResetPassword.call(token: params[:token], params: password_params.to_h)

    case result
    in Dry::Monads::Success
      render :success
    in Dry::Monads::Failure[ :invalid_token ]
      render :expired, status: :unprocessable_content
    in Dry::Monads::Failure[ :validation, user ]
      @user = user
      render :edit, status: :unprocessable_content
    end
  end

  private

  def find_user_by_token
    @user = User.find_by_password_reset_token(params[:token])
    render :expired, status: :not_found unless @user
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
