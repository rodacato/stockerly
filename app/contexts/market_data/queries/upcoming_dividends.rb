module MarketData
  module Queries
    # Public read API: returns upcoming dividends (ex_date today or later)
    # for the given assets, eager-loaded with their asset. Used by Trading
    # (dashboard "próximos dividendos") to project expected payouts.
    #
    # ADR-002: supplier-side wrapper. Trading must not call
    # `Dividend.upcoming.where(...)` directly from its presenters.
    class UpcomingDividends
      def self.call(asset_ids:)
        return Dividend.none if asset_ids.blank?

        Dividend.upcoming.where(asset_id: asset_ids).includes(:asset)
      end
    end
  end
end
