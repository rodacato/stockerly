module Usage
  module Queries
    # What the usage screen reads: each catalogued event and funnel per week,
    # newest first, which of those weeks the switch was on for, how long a
    # trade takes to capture, and the always-on day counters.
    class Report
      WEEKS = 8
      CAPTURE_DAYS = 30
      OPEN_DAYS = 14
      OPEN_PATHS = %w[/dashboard /alerts /signals /admin/usage].freeze

      def self.call(now: Time.current) = new(now).to_h

      def initialize(now)
        @now = now
        @today = now.to_date
        @weeks = (0...WEEKS).map { |back| (now - back.weeks).to_date.beginning_of_week }
        @enabled = Usage.enabled?
        @switched_at = Usage.switched_at
      end

      def to_h
        { enabled: @enabled, switched_at: @switched_at, weeks: @weeks, measured: measured,
          events: events, funnels: funnels, capture: capture, open_days: OPEN_DAYS,
          opens: OPEN_PATHS.index_with { |path| AppOpen.per_day(path: path, days: OPEN_DAYS, today: @today).sum(&:last) },
          panorama_days: AppOpen.per_day(path: "/dashboard", days: OPEN_DAYS, today: @today),
          help_opens: AppOpen.total(prefix: "help:", days: OPEN_DAYS, today: @today),
          discover_weeks: MarketData::Discover::VisitLog.weeks_seen(now: @now),
          discover_window: MarketData::Discover::VisitLog.window }
      end

      private

      # A week counts as measured when the switch was on for any of it. Only the
      # last flip is known, so an off-on-off history reads as its last stretch.
      def measured
        return @weeks.map { false } unless @switched_at

        flipped = @switched_at.to_date
        return @weeks.map { |week| week.end_of_week >= flipped } if @enabled

        recorded = UsageEvent.exists?
        @weeks.map { |week| recorded && week <= flipped }
      end

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
        p50, max = scope.pick(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY (properties->>'seconds')::int)"),
                              Arel.sql("max((properties->>'seconds')::int)"))
        { count: scope.count, p50: p50&.round, max: max }
      end

      def weekly(scope)
        scope.where(occurred_at: @weeks.last.beginning_of_day..@now)
             .group(Arel.sql("date_trunc('week', occurred_at)::date"))
      end

      def series(counts, name) = @weeks.map { |week| counts.fetch([ week, name ], 0) }
    end
  end
end
