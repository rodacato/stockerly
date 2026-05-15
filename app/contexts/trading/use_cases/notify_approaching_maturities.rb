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
        positions = approaching_positions.to_a
        notified_today = ids_notified_today(positions)

        positions.each do |position|
          next if notified_today.include?(position.id)
          days = days_until_maturity(position)
          next unless THRESHOLD_DAYS.include?(days)

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
        # Exclude day-0 in the query (the `THRESHOLD_DAYS` set starts at 1)
        # so the lookup matches the loop's actual fire-set.
        Position
          .where(status: :open)
          .where(maturity_date: (Date.current + 1)..(Date.current + THRESHOLD_DAYS.max.days))
          .includes(:asset, portfolio: :user)
      end

      def days_until_maturity(position)
        (position.maturity_date - Date.current).to_i
      end

      # Cooldown: at most one maturity_reminder per position per calendar day.
      # Pre-fetches the set of notified Position ids in a single query — avoids
      # the N+1 pattern of asking "did I notify this one today?" per iteration.
      # Threshold values are spaced by ≥2 days, so date-level dedup is enough
      # to prevent both same-day re-runs and accidental cross-threshold dupes.
      def ids_notified_today(positions)
        return Set.new if positions.empty?

        Notification
          .where(notifiable_type: "Position", notification_type: :maturity_reminder)
          .where(notifiable_id: positions.map(&:id))
          .where(created_at: Date.current.all_day)
          .pluck(:notifiable_id)
          .to_set
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
