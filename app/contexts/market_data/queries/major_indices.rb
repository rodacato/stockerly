module MarketData
  module Queries
    # Public read API: returns the headline market indices (SPX, IPC, etc.)
    # eager-loaded with their recent history for sparkline rendering.
    #
    # ADR-002: supplier-side wrapper. Trading must not call
    # `MarketIndex.major` directly from its use cases or controllers.
    class MajorIndices
      def self.call
        MarketIndex.major.includes(:market_index_histories)
      end
    end
  end
end
