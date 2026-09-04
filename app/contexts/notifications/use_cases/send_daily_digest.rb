module Notifications
  module UseCases
    # One email a day per user who asked for it, carrying the notifications the
    # app produced since the last digest. Users with nothing to report get no
    # email — an empty digest is noise, and noise is what the beta complained
    # about.
    class SendDailyDigest < SimpleUseCase
      WINDOW = 24.hours

      def call(since: WINDOW.ago)
        sent = 0

        subscribed_users.find_each do |user|
          notifications = user.notifications.where(created_at: since..).recent.to_a
          next if notifications.empty?

          AlertMailer.daily_digest(user, notifications).deliver_later
          sent += 1
        end

        sent
      end

      private

      def subscribed_users
        User.joins(:alert_preference).where(alert_preferences: { email_digest: true })
      end
    end
  end
end
