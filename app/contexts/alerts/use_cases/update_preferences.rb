module Alerts
  class UpdatePreferences < ApplicationUseCase
    def call(user:, params:)
      pref = user.alert_preference || user.create_alert_preference!
      pref.update!(params.slice(:email_digest, :browser_push, :sms_notifications))

      Success(pref)
    rescue ActiveRecord::RecordInvalid => e
      Failure([ :validation, e.message ])
    end
  end
end
