module Notifications
  module Queries
    # Public read API for the dedup question every notifying use case asks
    # before it calls `CreateNotification`. Notifications owns the "already
    # sent?" invariant; Trading and MarketData used to answer it themselves by
    # querying the `Notification` model directly.
    class AlreadySent
      def self.call(user:, notifiable:, notification_type:)
        Notification.where(
          user: user,
          notifiable: notifiable,
          notification_type: notification_type
        ).exists?
      end

      # The same question asked for a whole set at once, so a caller iterating
      # over rows does not pay one query per row. Returns the subset of
      # `notifiable_ids` already notified on `date`.
      def self.notifiable_ids_on(date:, notifiable_type:, notifiable_ids:, notification_type:)
        return Set.new if notifiable_ids.empty?

        Notification
          .where(notifiable_type: notifiable_type, notification_type: notification_type)
          .where(notifiable_id: notifiable_ids)
          .where(created_at: date.all_day)
          .pluck(:notifiable_id)
          .to_set
      end
    end
  end
end
