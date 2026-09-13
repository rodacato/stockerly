class ApplicationMailer < ActionMailer::Base
  default from: "Stockerly <noreply@#{Rails.application.config.action_mailer.default_url_options[:host]}>"
  layout "mailer"
  helper :application
end
