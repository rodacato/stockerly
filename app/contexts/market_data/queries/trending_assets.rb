module MarketData
  module Queries
    # Public read API: returns stock assets with non-nil price and 24h change,
    # ordered by absolute change magnitude descending. Used by Trading
    # (dashboard sidebar) for the "movers today" surface.
    #
    # ADR-002: supplier-side wrapper. Trading must not reach into
    # `Asset.where(asset_type: :stock)...` directly.
    class TrendingAssets
      def self.call(limit: 5)
        Asset.where(asset_type: :stock)
             .where.not(current_price: nil)
             .where.not(change_percent_24h: nil)
             .includes(:trend_scores)
             .order(Arel.sql("ABS(change_percent_24h) DESC"))
             .limit(limit)
      end
    end
  end
end
