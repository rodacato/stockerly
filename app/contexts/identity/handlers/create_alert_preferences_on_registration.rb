module Identity
  module Handlers
    class CreateAlertPreferencesOnRegistration
      def self.call(event)
        user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
        user = User.find(user_id)
        return if user.alert_preference.present?

        user.create_alert_preference!(
          email_digest: true,
          browser_push: true,
          sms_notifications: false
        )
      end
    end
  end
end
