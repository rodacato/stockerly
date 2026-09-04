module Administration
  module UseCases
    module Onboarding
      class SeedAssets < SimpleUseCase
        def call(symbols:)
          return { created: 0 } if symbols.blank?

          entries = Administration::Domain::AssetCatalog.find_by_symbols(symbols)
          created = 0

          entries.each do |entry|
            Asset.find_or_create_by!(symbol: entry[:symbol]) do |a|
              a.name = entry[:name]
              a.asset_type = entry[:asset_type]
              a.exchange = entry[:exchange]
              a.sector = entry[:sector]
              a.country = entry[:country]
              a.data_source = entry[:data_source]
              a.sync_status = :active
            end
            created += 1
          end

          { created: created }
        end
      end
    end
  end
end
