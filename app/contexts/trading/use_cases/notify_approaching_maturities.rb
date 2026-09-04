module Trading
  module UseCases
    # Fires a once-per-day notification for each open fixed-income position
    # whose lot-level maturity falls on a configured threshold (7, 3, 1 days
    # away). Mirrors NotifyApproachingEarnings, its sibling in this context
    # (#29 JTBD #3).
    #
    # Copy is descriptive per ADR-001: "CETES_28D expires in 5 days" — never
    # "consider reinvesting" or any action verb directed at the user.
    class NotifyApproachingMaturities < SimpleUseCase
      THRESHOLD_DAYS = [ 7, 3, 1 ].freeze

      def call
        sent = 0
        positions = approaching_positions.to_a
        notified_today = ids_notified_today(positions)

        positions.each do |position|
          next if notified_today.include?(position.id)
          days = days_until_maturity(position)
          next unless THRESHOLD_DAYS.include?(days)

          Notifications::UseCases::CreateNotification.call(
            user_id: position.portfolio.user.id,
            title: title_for(position, days),
            body: body_for(position, days),
            notification_type: :maturity_reminder,
            notifiable: position
          )
          sent += 1
        end

        sent
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
        Notifications::Queries::AlreadySent.notifiable_ids_on(
          date: Date.current,
          notifiable_type: "Position",
          notifiable_ids: positions.map(&:id),
          notification_type: :maturity_reminder
        )
      end

      def title_for(position, days)
        "#{position.asset.symbol} vence #{when_phrase(days)}"
      end

      def body_for(position, days)
        "Tu posición en #{position.asset.name} (#{position.shares.to_i} unidades, " \
          "vence el #{format_date_es(position.maturity_date)}) #{when_phrase(days)}."
      end

      def when_phrase(days)
        days == 1 ? "mañana" : "en #{days} días"
      end

      def format_date_es(date)
        I18n.l(date, format: :day_month_year)
      end
    end
  end
end
