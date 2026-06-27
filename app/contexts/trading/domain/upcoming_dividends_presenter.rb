# Presents upcoming dividends for a portfolio's open positions.
# Each row is tagged with the dividend's native currency — dividends are
# paid in the issuer's currency, so converting to user.preferred_currency
# would lie about what the user actually receives.
module Trading
  module Domain
    class UpcomingDividendsPresenter
      UpcomingDividend = Data.define(:asset, :ex_date, :pay_date, :amount_per_share, :shares, :expected_total, :currency)

      def initialize(portfolio)
        @portfolio = portfolio
      end

      def upcoming
        open_positions = @portfolio.positions.open.includes(:asset)
        return [] if open_positions.empty?

        asset_ids = open_positions.map(&:asset_id)
        dividends = MarketData::Queries::UpcomingDividends.call(asset_ids: asset_ids)

        shares_by_asset = open_positions.each_with_object({}) do |pos, hash|
          hash[pos.asset_id] = pos.shares
        end

        dividends.map do |div|
          shares = shares_by_asset[div.asset_id] || 0
          UpcomingDividend.new(
            asset: div.asset,
            ex_date: div.ex_date,
            pay_date: div.pay_date,
            amount_per_share: div.amount_per_share,
            shares: shares,
            expected_total: shares * div.amount_per_share,
            currency: div.currency
          )
        end
      end
    end
  end
end
