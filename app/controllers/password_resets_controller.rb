class PasswordResetsController < ApplicationController
  layout "public"

  rate_limit to: 3, within: 1.hour, only: :create

  before_action :find_user_by_token, only: [:edit, :update]

  def new; end

  # TODO: Replace with Identity::RequestPasswordReset.call(email:)
  #       -> Success(token_url) | Failure(:not_found)
  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user
      token = user.password_reset_token
      reset_url = reset_password_url(token)
      Rails.logger.info "[PASSWORD RESET] Reset URL for #{user.email}: #{reset_url}"
    end

    redirect_to login_path, notice: "If that email exists, you'll receive reset instructions shortly."
  end

  def edit; end

  # TODO: Replace with Identity::ResetPassword.call(token:, password:, password_confirmation:)
  #       -> Success(user) | Failure(:invalid_token) | Failure(:validation, errors)
  def update
    if @user.update(password_params)
      @user.remember_tokens.destroy_all
      redirect_to login_path, notice: "Password reset successfully. Please sign in."
    else
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
