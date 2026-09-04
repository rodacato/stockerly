module Trading
  module UseCases
    # Fires a once-per-asset notification for each earnings date landing inside
    # the lookahead window, to whoever is following that asset — the watchlist
    # and the open-position sets merged.
    #
    # Trading-owned because the audience lives in this context: WatchlistItem
    # and Position answer "who is following this asset", and ADR-002 makes the
    # Trading -> MarketData read one-directional, so the earnings dates arrive
    # through MarketData::Queries::UpcomingEarnings rather than the reverse.
    #
    # Copy is descriptive per ADR-001: "AAPL reporta resultados el 3 sep" —
    # never an action verb directed at the user.
    class NotifyApproachingEarnings < SimpleUseCase
      LOOKAHEAD_DAYS = 3

      def call
        upcoming_events = MarketData::Queries::UpcomingEarnings.within(days: LOOKAHEAD_DAYS)

        return 0 if upcoming_events.empty?

        count = 0
        upcoming_events.each do |event|
          users_following(event.asset).each do |user|
            next if already_notified?(user, event)

            Notifications::UseCases::CreateNotification.call(
              user_id: user.id,
              title: "#{event.asset.symbol} reporta resultados el #{format_date_es(event.report_date)}",
              body:  "#{event.asset.name} reporta #{when_phrase_es(event.report_date)}. EPS estimado: #{event.estimated_eps || 'N/D'}.",
              notification_type: :earnings_reminder,
              notifiable: event
            )
            count += 1
          end
        end

        count
      end

      MONTHS_ES = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

      private

      def users_following(asset)
        watching = WatchlistItem.where(asset: asset).pluck(:user_id)
        holding = Position.where(asset: asset, status: :open).joins(:portfolio).pluck("portfolios.user_id")
        User.where(id: (watching + holding).uniq)
      end

      def already_notified?(user, event)
        Notifications::Queries::AlreadySent.call(
          user: user,
          notifiable: event,
          notification_type: :earnings_reminder
        )
      end

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
