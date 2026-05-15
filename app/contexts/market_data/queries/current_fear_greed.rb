module MarketData
  module Queries
    # Public read API: returns the latest crypto and stocks Fear & Greed
    # readings, plus their recent history as [fetched_at, value] tuples
    # ready for an SVG sparkline.
    #
    # ADR-002: supplier-side wrapper. Trading must not reach into
    # `FearGreedReading.latest_*` or `FearGreedReading.crypto.recent` from
    # outside MarketData.
    class CurrentFearGreed
      def self.call
        {
          crypto: FearGreedReading.latest_crypto,
          stocks: FearGreedReading.latest_stocks,
          crypto_history: FearGreedReading.crypto.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value),
          stocks_history: FearGreedReading.stocks.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value)
        }
      end
    end
  end
end
