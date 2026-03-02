class EmailVerificationsController < ApplicationController
  before_action :require_authentication, only: :create
  rate_limit to: 3, within: 1.hour, only: :create

  def show
    result = Identity::UseCases::VerifyEmail.call(params: { token: params[:token] })

    case result
    in Dry::Monads::Success
      redirect_to (current_user ? dashboard_path : login_path),
                  notice: "Email verified successfully!"
    in Dry::Monads::Failure[ :invalid_token, message ]
      redirect_to (current_user ? dashboard_path : login_path),
                  alert: message
    in Dry::Monads::Failure[ :validation, _ ]
      redirect_to (current_user ? dashboard_path : login_path),
                  alert: "Invalid verification link."
    end
  end

  def create
    user = current_user

    if user.email_verified?
      redirect_to dashboard_path, notice: "Your email is already verified."
      return
    end

    token = user.generate_token_for(:email_verification)
    host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
    verification_url = Rails.application.routes.url_helpers.verify_email_url(token, host: host)

    if Rails.env.production?
      UserMailer.verify_email(user, verification_url).deliver_later
    else
      Rails.logger.info "[EMAIL VERIFICATION] Resent verification URL for #{user.email}: #{verification_url}"
    end

    redirect_to dashboard_path, notice: "Verification email sent! Check your inbox."
  end

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end
end
