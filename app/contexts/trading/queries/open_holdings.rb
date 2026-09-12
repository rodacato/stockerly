module Trading
  module Queries
    # Public read API: what the owner holds, as plain data. ADR-0025 — a
    # consumer outside Trading must not reach into Position or Asset, so what
    # crosses the boundary carries no ActiveRecord and no behaviour: only the
    # four facts a caller needs to reason about a holding.
    class OpenHoldings
      def self.call(user:)
        portfolio = user&.portfolio
        return [] if portfolio.nil?

        portfolio.positions.open.includes(:asset).map do |position|
          {
            symbol: position.asset.symbol,
            asset_type: position.asset.asset_type,
            shares: position.shares,
            market_value: position.market_value
          }
        end
      end
    end
  end
end
