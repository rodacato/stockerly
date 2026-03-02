# Presents upcoming dividends for a portfolio's open positions.
# Calculates expected payout based on current shares held.
module Trading
  module Domain
    class UpcomingDividendsPresenter
      UpcomingDividend = Data.define(:asset, :ex_date, :pay_date, :amount_per_share, :shares, :expected_total)

      def initialize(portfolio)
        @portfolio = portfolio
      end

      def upcoming
        open_positions = @portfolio.positions.open.includes(:asset)
        return [] if open_positions.empty?

        asset_ids = open_positions.map(&:asset_id)
        dividends = Dividend.upcoming.where(asset_id: asset_ids).includes(:asset)

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
            expected_total: shares * div.amount_per_share
          )
        end
      end
    end
  end
end
