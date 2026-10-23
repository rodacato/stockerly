module Usage
  module Queries
    # What the usage screen reads: each catalogued event and funnel per week,
    # how long a trade takes to capture, and the always-on day counters.
    class Report
      WEEKS = 8
      CAPTURE_DAYS = 30
      OPEN_PATHS = %w[/dashboard /alerts /signals /admin/usage].freeze

      def self.call(now: Time.current) = new(now).to_h

      def initialize(now)
        @now = now
        @weeks = (0...WEEKS).map { |back| (now - back.weeks).to_date.beginning_of_week }.reverse
      end

      def to_h
        { enabled: Usage.enabled?, weeks: @weeks, events: events, funnels: funnels, capture: capture,
          opens: OPEN_PATHS.index_with { |path| AppOpen.per_day(path: path, today: @now.to_date) },
          help_opens: AppOpen.total(prefix: "help:", today: @now.to_date),
          discover_weeks: MarketData::Discover::VisitLog.weeks_seen(now: @now) }
      end

      private

      def events
        counts = weekly(UsageEvent.all).group(:name).count
        Domain::Catalogue::EVENTS.values.index_with { |event| series(counts, event.name) }
      end

      def funnels
        offers = weekly(UsageEvent.all).group(:name).count
        Domain::Funnels::ALL.map do |funnel|
          taken = weekly(UsageEvent.where(name: funnel.action).where("properties->>'via' = ?", funnel.via)).count
          { funnel: funnel, rows: @weeks.map { |week| [ week, offers.fetch([ week, funnel.offer ], 0), taken.fetch(week, 0) ] } }
        end
      end

      # Seconds from opening the trade sheet to saving it, over the last month.
      def capture
        scope = UsageEvent.where(name: "trade.created", occurred_at: (@now - CAPTURE_DAYS.days)..@now).where("properties ? 'seconds'")
        p50, p95 = scope.pick(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY (properties->>'seconds')::int)"),
                              Arel.sql("percentile_cont(0.95) WITHIN GROUP (ORDER BY (properties->>'seconds')::int)"))
        { count: scope.count, p50: p50&.round, p95: p95&.round }
      end

      def weekly(scope)
        scope.where(occurred_at: @weeks.first.beginning_of_day..@now)
             .group(Arel.sql("date_trunc('week', occurred_at)::date"))
      end

      def series(counts, name) = @weeks.map { |week| counts.fetch([ week, name ], 0) }
    end
  end
end
