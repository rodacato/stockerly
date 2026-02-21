class PasswordResetsController < ApplicationController
  layout "public"

  rate_limit to: 3, within: 1.hour, only: :create

  before_action :find_user_by_token, only: [:edit, :update]

  def new; end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user
      raw_token = user.generate_password_reset_token!
      reset_url = reset_password_url(raw_token)
      Rails.logger.info "[PASSWORD RESET] Reset URL for #{user.email}: #{reset_url}"
    end

    redirect_to login_path, notice: "If that email exists, you'll receive reset instructions shortly."
  end

  def edit; end

  def update
    if @user.update(password_params.merge(password_reset_token: nil, password_reset_sent_at: nil))
      @user.remember_tokens.destroy_all
      redirect_to login_path, notice: "Password reset successfully. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_token
    digest = Digest::SHA256.hexdigest(params[:token])
    @user = User.find_by(password_reset_token: digest)

    unless @user && !@user.password_reset_expired?
      redirect_to forgot_password_path, alert: "Invalid or expired reset link."
    end
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
