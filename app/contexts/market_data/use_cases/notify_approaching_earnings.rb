module MarketData
  module UseCases
    class NotifyApproachingEarnings < ApplicationUseCase
      LOOKAHEAD_DAYS = 3

      def call
        upcoming_events = EarningsEvent
          .where(report_date: Date.current..(Date.current + LOOKAHEAD_DAYS.days))
          .includes(:asset)

        return Success(0) if upcoming_events.empty?

        count = 0
        upcoming_events.each do |event|
          users_watching(event.asset).each do |user|
            next if already_notified?(user, event)

            Notification.create!(
              user: user,
              title: "#{event.asset.symbol} earnings on #{event.report_date.strftime('%b %d')}",
              body: "#{event.asset.name} reports earnings #{event.report_date == Date.current ? 'today' : "in #{(event.report_date - Date.current).to_i} days"}. Estimated EPS: #{event.estimated_eps || 'N/A'}.",
              notification_type: :earnings_reminder,
              notifiable: event
            )
            count += 1
          end
        end

        Success(count)
      end

      private

      def users_watching(asset)
        user_ids = WatchlistItem.where(asset: asset).pluck(:user_id)
        position_user_ids = Position.where(asset: asset, status: :open).joins(:portfolio).pluck("portfolios.user_id")
        User.where(id: (user_ids + position_user_ids).uniq)
      end

      def already_notified?(user, event)
        Notification.where(
          user: user,
          notifiable: event,
          notification_type: :earnings_reminder
        ).exists?
      end
    end
  end
end
