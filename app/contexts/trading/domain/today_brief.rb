module Trading
  module Domain
    # What the daily view says before it shows anything: a first run, quotes it
    # cannot vouch for, a short list of things worth a look, or that nothing is.
    # "Nothing" is only ever claimed over quotes it can vouch for (ADR-023).
    class TodayBrief
      LIMIT = 3
      NEAR_TARGET_PERCENT = 5.0
      PRIORITY = { maturity: 0, earnings: 1, target: 2 }.freeze

      Item = Data.define(:kind, :asset, :days, :date, :gap)
      Result = Data.define(:state, :items, :total)

      def self.call(tracks_anything:, quotes_reliable:, candidates:)
        return Result.new(:first_run, [], 0) unless tracks_anything

        usable = quotes_reliable ? candidates : candidates.reject { |item| item.kind == :target }
        ranked = usable.sort_by { |item| [ PRIORITY.fetch(item.kind), item.days || item.gap ] }

        Result.new(state_for(quotes_reliable, ranked), ranked.first(LIMIT), ranked.size)
      end

      def self.state_for(quotes_reliable, ranked)
        return :stale unless quotes_reliable

        ranked.empty? ? :calm : :items
      end
      private_class_method :state_for
    end
  end
end
