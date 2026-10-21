module MarketData
  module Queries
    # Public read API: the latest VIX reading and its level, or nil when there is
    # none or it is older than the window (ADR-0023: a stale gauge is absent,
    # not a calm one). The window spans a weekend, when the index does not move.
    #
    # ADR-002: Trading asks this rather than `MarketIndex.vix`.
    class CurrentVolatility
      WINDOW = 4.days

      Reading = Data.define(:value, :level, :as_of)

      def self.call(now: Time.current)
        vix = MarketIndex.vix
        return nil if vix.nil? || vix.value.nil? || vix.updated_at < now - WINDOW

        Reading.new(value: vix.value, level: Domain::VolatilityLevel.for(vix.value), as_of: vix.updated_at.to_date)
      end
    end
  end
end
