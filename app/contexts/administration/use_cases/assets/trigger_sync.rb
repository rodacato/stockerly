module Administration
  module Assets
    class TriggerSync < ApplicationUseCase
      def call(asset_id: nil, asset_type: nil)
        if asset_id
          asset = Asset.find_by(id: asset_id)
          return Failure([ :not_found, "Asset not found" ]) unless asset

          SyncSingleAssetJob.perform_later(asset.id)
          Success(:single_sync_enqueued)
        else
          SyncAllAssetsJob.perform_later(asset_type)
          Success(:bulk_sync_enqueued)
        end
      end
    end
  end
end
