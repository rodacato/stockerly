module Administration
  module UseCases
    module Assets
      class DeleteAsset < ApplicationUseCase
        def call(asset_id:, admin:)
          asset = Asset.find_by(id: asset_id)
          return Failure([ :not_found, "Asset not found" ]) unless asset

          symbol = asset.symbol
          asset.destroy!

          publish(MarketData::Events::AssetDeleted.new(asset_symbol: symbol, admin_id: admin.id))

          Success(symbol)
        end
      end
    end
  end
end
