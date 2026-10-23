module MarketData
  module Queries
    # Public read API: returns the latest crypto Fear & Greed reading plus its
    # recent history as [fetched_at, value] tuples ready for an SVG sparkline.
    # Stocks went with CNN's gauge (D38) — its index is a proprietary composite
    # with no equivalent source, so there is nothing to read.
    #
    # ADR-002: supplier-side wrapper. Trading must not reach into
    # `FearGreedReading.latest_*` or `FearGreedReading.crypto.recent` from
    # outside MarketData.
    class CurrentFearGreed
      def self.call
        {
          crypto: FearGreedReading.latest_crypto,
          crypto_history: FearGreedReading.crypto.recent.pluck(:fetched_at, :value).reverse
        }
      end
    end
  end
end
