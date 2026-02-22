module Onboarding
  class LoadAssetCatalog < ApplicationUseCase
    def call(types: [:stock, :crypto], limit: 20)
      assets = Asset.where(asset_type: types)
                    .order(:name)
                    .limit(limit)

      Success({ assets: assets })
    end
  end
end
