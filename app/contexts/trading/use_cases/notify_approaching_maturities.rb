module Trading
  module UseCases
    # Fires a once-per-day notification for each open fixed-income position
    # whose lot-level maturity falls on a configured threshold (7, 3, 1 days
    # away). Mirrors MarketData::UseCases::NotifyApproachingEarnings but is
    # Trading-owned because Position.maturity_date lives in this context
    # (#29 JTBD #3).
    #
    # Copy is descriptive per ADR-001: "CETES_28D expires in 5 days" — never
    # "consider reinvesting" or any action verb directed at the user.
    class NotifyApproachingMaturities < ApplicationUseCase
      THRESHOLD_DAYS = [ 7, 3, 1 ].freeze

      def call
        sent = 0

        approaching_positions.each do |position|
          days = days_until_maturity(position)
          next unless THRESHOLD_DAYS.include?(days)
          next if already_notified_today?(position)

          Notification.create!(
            user: position.portfolio.user,
            title: title_for(position, days),
            body: body_for(position, days),
            notification_type: :maturity_reminder,
            notifiable: position
          )
          sent += 1
        end

        Success(sent)
      end

      private

      def approaching_positions
        Position
          .where(status: :open)
          .where(maturity_date: Date.current..(Date.current + THRESHOLD_DAYS.max.days))
          .includes(:asset, portfolio: :user)
      end

      def days_until_maturity(position)
        (position.maturity_date - Date.current).to_i
      end

      # Cooldown: at most one maturity_reminder per position per calendar day.
      # The job runs daily and THRESHOLD_DAYS values are spaced by ≥2 days, so
      # this date-level dedup is sufficient to prevent both same-day re-runs
      # and accidental cross-threshold duplicates.
      def already_notified_today?(position)
        Notification
          .where(notifiable: position, notification_type: :maturity_reminder)
          .where(created_at: Date.current.all_day)
          .exists?
      end

      def title_for(position, days)
        "#{position.asset.symbol} expires #{when_phrase(days)}"
      end

      def body_for(position, days)
        "Your #{position.asset.name} position (#{position.shares.to_i} units, " \
          "matures on #{position.maturity_date.strftime('%b %d, %Y')}) expires #{when_phrase(days)}."
      end

      def when_phrase(days)
        days == 1 ? "tomorrow" : "in #{days} days"
      end
    end
  end
end
