module MarketData
  module UseCases
    # Read query for /earnings (S10 #100). Returns two chronological
    # sections — upcoming (next N days) and recent (previous 7 days) —
    # filtered by mercado / período / watchlist, plus the KPI counts the
    # header band displays ("Esta semana", "En tu watchlist").
    #
    # ADR-006: pure read, no failure path → SimpleUseCase.
    class ListEarnings < SimpleUseCase
      PERIODS = {
        "semana"    =>  7,
        "mes"       => 30,
        "trimestre" => 90
      }.freeze

      DEFAULT_PERIOD     = "semana"
      RECENT_WINDOW_DAYS = 7

      def call(user:, periodo: DEFAULT_PERIOD, mercado: "todos", watchlist_only: false)
        periodo = DEFAULT_PERIOD unless PERIODS.key?(periodo.to_s)
        days    = PERIODS[periodo.to_s]

        watchlist_asset_ids = user.watchlist_items.pluck(:asset_id)

        upcoming = EarningsEvent.upcoming_window(days)
        recent   = EarningsEvent.recent_window(RECENT_WINDOW_DAYS)

        upcoming = upcoming.for_market(mercado)
        recent   = recent.for_market(mercado)

        if watchlist_only
          upcoming = upcoming.where(asset_id: watchlist_asset_ids)
          recent   = recent.where(asset_id: watchlist_asset_ids)
        end

        upcoming = upcoming.includes(:asset).to_a
        recent   = recent.includes(:asset).to_a

        {
          periodo:        periodo,
          mercado:        mercado,
          watchlist_only: watchlist_only,
          upcoming:       group_by_day(upcoming),
          recent:         recent,
          counts: {
            upcoming:  upcoming.length,
            recent:    recent.length,
            watchlist: upcoming.count { |e| watchlist_asset_ids.include?(e.asset_id) }
          }
        }
      end

      private

      # Groups upcoming events by report_date in ascending order. Returns an
      # Array<[Date, Array<EarningsEvent>]> so the view can render one section
      # per day without an extra sort pass.
      def group_by_day(events)
        events.group_by(&:report_date).sort_by(&:first)
      end
    end
  end
end
