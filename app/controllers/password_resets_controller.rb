class PasswordResetsController < ApplicationController
  layout "public"

  rate_limit to: 3, within: 1.hour, only: :create

  before_action :find_user_by_token, only: [ :edit ]

  def new; end

  def create
    Identity::UseCases::RequestPasswordReset.call(params: { email: params[:email] })
    redirect_to login_path, notice: "If that email exists, you'll receive reset instructions shortly."
  end

  def edit; end

  def update
    result = Identity::UseCases::ResetPassword.call(token: params[:token], params: password_params.to_h)

    case result
    in Dry::Monads::Success
      redirect_to login_path, notice: "Password reset successfully. Please sign in."
    in Dry::Monads::Failure[ :invalid_token, message ]
      redirect_to forgot_password_path, alert: message
    in Dry::Monads::Failure[ :validation, _ ]
      render :edit, status: :unprocessable_content
    end
  end

  private

  def find_user_by_token
    @user = User.find_by_password_reset_token(params[:token])

    unless @user
      redirect_to forgot_password_path, alert: "Invalid or expired reset link."
    end
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
