class SendVerificationEmailOnRegistration
  def self.async? = true

  def self.call(event)
    user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
    user = User.find_by(id: user_id)
    return unless user
    return if user.email_verified?

    token = user.generate_token_for(:email_verification)
    host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
    verification_url = Rails.application.routes.url_helpers.verify_email_url(token, host: host)

    if Rails.env.production?
      UserMailer.verify_email(user, verification_url).deliver_later
    else
      Rails.logger.info "[EMAIL VERIFICATION] Verification URL for #{user.email}: #{verification_url}"
    end
  end
end
