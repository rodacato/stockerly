module Administration
  module UseCases
    module Assets
      class CreateAsset < ApplicationUseCase
        def call(admin:, params:)
          attrs = yield validate(Administration::Contracts::Assets::CreateContract, params)
          attrs = resolve_logo_url(attrs)
          attrs = resolve_data_source(attrs)
          asset = yield persist(attrs)
          _     = yield publish(Administration::Events::AssetCreated.new(
            asset_id: asset.id,
            symbol: asset.symbol,
            admin_id: admin.id
          ))

          Success(asset)
        end

        private

        # The catalogue owns where a logo comes from — this path and
        # `stockerly:seed_assets` used to answer it separately.
        def resolve_logo_url(attrs)
          return attrs if attrs[:logo_url].present?

          attrs.merge(logo_url: Administration::Domain::AssetCatalog.logo_url_for(
            symbol: attrs[:symbol], asset_type: attrs[:asset_type], country: attrs[:country]
          ))
        end

        # Left blank on purpose: data_source records which gateway last served
        # this asset's price, and the first sync is what knows that. Guessing it
        # from the country is how the asset detail came to name a provider that
        # had not served it in months.
        def resolve_data_source(attrs)
          attrs.merge(data_source: nil)
        end

        def persist(attrs)
          asset = Asset.new(attrs.merge(sync_status: :active))
          asset.save ? Success(asset) : Failure([ :validation, asset.errors.to_hash ])
        end
      end
    end
  end
end
