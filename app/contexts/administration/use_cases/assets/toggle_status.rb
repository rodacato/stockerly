module Administration
  module UseCases
    module Assets
      class ToggleStatus < ApplicationUseCase
        def call(asset_id:)
          asset = Asset.find_by(id: asset_id)
          return Failure([ :not_found, "Asset not found" ]) unless asset

          new_status = asset.active? ? :disabled : :active
          asset.update!(sync_status: new_status)

          Success(asset)
        end
      end
    end
  end
end
