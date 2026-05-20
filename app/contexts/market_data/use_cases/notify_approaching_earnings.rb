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
              title: "#{event.asset.symbol} reporta resultados el #{format_date_es(event.report_date)}",
              body:  "#{event.asset.name} reporta #{when_phrase_es(event.report_date)}. EPS estimado: #{event.estimated_eps || 'N/D'}.",
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

      MONTHS_ES = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

      def format_date_es(date)
        "#{date.day} #{MONTHS_ES[date.month - 1]}"
      end

      def when_phrase_es(date)
        days = (date - Date.current).to_i
        return "hoy" if days == 0
        return "mañana" if days == 1
        "en #{days} días"
      end
    end
  end
end
