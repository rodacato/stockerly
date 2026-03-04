module Administration
  module Handlers
    class SendReactivationEmail
      def self.async? = true

      def self.call(event)
        user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
        user = User.find_by(id: user_id)
        return unless user

        UserMailer.account_reactivated(user).deliver_later if defined?(UserMailer)
      end
    end
  end
end
