module Identity
  class RequestPasswordReset < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Identity::RequestPasswordResetContract, params)

      process_reset(attrs[:email])

      Success(:sent)
    end

    private

    def process_reset(email)
      user = User.find_by(email: email&.downcase&.strip)
      return unless user

      token = user.password_reset_token
      host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
      reset_url = Rails.application.routes.url_helpers.reset_password_url(token, host: host)

      if Rails.env.production?
        UserMailer.password_reset(user, reset_url).deliver_later
      else
        Rails.logger.info "[PASSWORD RESET] Reset URL for #{user.email}: #{reset_url}"
      end
    end
  end
end
