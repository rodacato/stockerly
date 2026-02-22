module Watchlist
  class AddAsset < ApplicationUseCase
    def call(user:, asset_id:)
      asset = yield find_asset(asset_id)
      item  = yield create_item(user, asset)

      Success(item)
    end

    private

    def find_asset(asset_id)
      asset = Asset.find_by(id: asset_id)
      asset ? Success(asset) : Failure([:not_found, "Asset not found"])
    end

    def create_item(user, asset)
      item = user.watchlist_items.build(asset: asset)
      if item.save
        Success(item)
      else
        Failure([:validation, item.errors.to_hash])
      end
    end
  end
end
