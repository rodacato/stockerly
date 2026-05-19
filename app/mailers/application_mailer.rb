class ApplicationMailer < ActionMailer::Base
  default from: "Stockerly <noreply@stockerly.notdefined.dev>"
  layout "mailer"
  helper :application
end
