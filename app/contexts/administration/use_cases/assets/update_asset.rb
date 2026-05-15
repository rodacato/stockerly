module Administration
  module UseCases
    module Assets
      class UpdateAsset < ApplicationUseCase
        def call(admin:, params:)
          attrs   = yield validate(Administration::Contracts::Assets::UpdateContract, params)
          asset   = yield find(attrs[:id])
          changes = yield update(asset, attrs)

          # Only publish (and therefore audit-log) when something actually
          # changed. An empty changes hash means the admin submitted the
          # same values as the current state — that's a no-op, not an event.
          if changes.any?
            _ = yield publish(Administration::Events::AssetUpdated.new(
              asset_id: asset.id,
              admin_id: admin.id,
              symbol: asset.symbol,
              changes: changes
            ))
          end

          Success(asset)
        end

        private

        def find(id)
          asset = Asset.find_by(id: id)
          asset ? Success(asset) : Failure([ :not_found, "Asset not found" ])
        end

        def update(asset, attrs)
          update_attrs = attrs.except(:id).compact

          return Success({}) if update_attrs.empty?

          changes = update_attrs.each_with_object({}) do |(key, value), hash|
            old_value = asset.send(key)
            hash[key.to_s] = { from: old_value, to: value } if old_value != value
          end

          asset.update!(update_attrs) if update_attrs.present?
          Success(changes)
        end
      end
    end
  end
end
