module Notifications
  module Handlers
    # Interrupts the user by email the moment a rule fires — but only for users
    # who asked for it, and only for fired rules. Earnings and maturity notices
    # have a date, not an urgency: they ride the daily digest.
    class SendUrgentEmail
      def self.async? = true

      def self.call(event)
        notification_id = event.is_a?(Hash) ? event[:notification_id] : event.notification_id
        notification = Notification.find_by(id: notification_id)
        return unless notification&.alert_triggered?

        user = notification.user
        return unless user&.alert_preference&.urgent_email

        AlertMailer.urgent_alert(user, notification).deliver_later
      end
    end
  end
end
