module Market
  class LoadAssetDetail < ApplicationUseCase
    def call(symbol:)
      asset = Asset.find_by(symbol: symbol.upcase)
      return Failure([ :not_found, "Asset not found" ]) unless asset

      fundamental = resolve_fundamental(asset)
      presenter = FundamentalPresenter.new(asset: asset, fundamental: fundamental)

      Success({
        asset: asset,
        presenter: presenter,
        has_fundamentals: fundamental.present?
      })
    end

    private

    def resolve_fundamental(asset)
      if asset.asset_type_crypto?
        asset.asset_fundamentals.where(period_label: "CRYPTO_MARKET").latest.first
      else
        calculated = asset.asset_fundamentals.where(period_label: "CALCULATED").latest.first
        calculated || asset.asset_fundamentals.overview.latest.first
      end
    end
  end
end
