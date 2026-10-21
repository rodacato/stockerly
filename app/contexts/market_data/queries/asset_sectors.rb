module MarketData
  module Queries
    # Public read API: the sector of each asset. `assets.sector` is identity the
    # catalogue owner sets at creation (ADR-024) and it is often blank for a
    # stock the provider's own overview does classify, so the overview answers
    # where the column does not. ETFs, crypto and fixed income have none: absent.
    #
    # ADR-002: Trading asks this rather than reading the fundamentals table.
    class AssetSectors
      def self.call(assets:)
        overview = AssetFundamental.overview.where(asset_id: assets.map(&:id)).order(:calculated_at)
                                   .pluck(:asset_id, Arel.sql("metrics ->> 'sector'")).to_h

        assets.to_h { |asset| [ asset.id, asset.sector.presence || overview[asset.id].presence ] }
      end
    end
  end
end
