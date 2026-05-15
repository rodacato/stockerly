module Administration
  module UseCases
    module Assets
      # ADR-006: single-resource mutation with the canonical 404 failure
      # path. `find` raises ActiveRecord::RecordNotFound; the controller
      # handles that with a flash + redirect.
      class ToggleStatus < SimpleUseCase
        def call(asset_id:)
          asset = Asset.find(asset_id)
          asset.update!(sync_status: asset.active? ? :disabled : :active)
          asset
        end
      end
    end
  end
end
