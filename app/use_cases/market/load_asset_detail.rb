module Market
  class LoadAssetDetail < ApplicationUseCase
    def call(symbol:)
      asset = Asset.find_by(symbol: symbol.upcase)
      return Failure([ :not_found, "Asset not found" ]) unless asset

      overview = asset.asset_fundamentals.overview.latest.first
      calculated = asset.asset_fundamentals.where(period_label: "CALCULATED").latest.first
      fundamental = calculated || overview

      presenter = FundamentalPresenter.new(asset: asset, fundamental: fundamental)

      Success({
        asset: asset,
        presenter: presenter,
        has_fundamentals: fundamental.present?
      })
    end
  end
end
