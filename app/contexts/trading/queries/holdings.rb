module Trading
  module Queries
    # Public read API (ADR-031's 2026-10-22 amendment): the owner's holdings with
    # the figures Activos states, from the same PositionBreakdown and
    # PortfolioSummary, as plain data. A missing price or rate makes the whole
    # valuation unknown, never a partial total.
    class Holdings
      def self.call(user: User.first)
        portfolio = user&.portfolio
        return nil unless portfolio&.open_positions&.exists?

        Domain::FxDegradation.new.figure { new(portfolio, user.preferred_currency).to_h }
      end

      def initialize(portfolio, currency)
        @portfolio = portfolio
        @currency = currency
        @summary = Domain::PortfolioSummary.prewarmed(portfolio, currency: currency)
      end

      def to_h
        total = @summary.total_value
        { currency: @currency, prices_as_of: @summary.prices_as_of, total: totals(total), positions: positions(total) }
      end

      private

      def totals(total)
        gain = @summary.unrealized_gain
        day = @summary.day_gain
        { value: total, cost: @summary.total_invested, gain: gain.absolute, gain_percent: gain.percent,
          day_gain: day&.absolute, day_gain_percent: day&.percent }
      end

      def positions(total)
        @portfolio.open_positions.includes(:asset, :trades).map { |position| position_h(position, total) }
                  .sort_by { |position| [ -position[:value], position[:symbol] ] }
      end

      def position_h(position, total)
        asset = position.asset
        breakdown = Domain::PositionBreakdown.new(position, currency: @currency)
        { symbol: asset.symbol, name: asset.name, asset_type: asset.asset_type, shares: position.shares,
          value: breakdown.market_value, cost: breakdown.cost_basis,
          gain: breakdown.total.amount, gain_percent: breakdown.total.percent,
          from_asset: breakdown.from_asset.amount, from_fx: breakdown.from_fx.amount,
          share_percent: total.positive? ? (breakdown.market_value / total * 100).to_f : nil,
          maturity_date: position.maturity_date }
      end
    end
  end
end
