module Administration
  module UseCases
    module Assets
      # Creates every asset the catalogue declares, and corrects the fields on
      # rows that predate a catalogue change. The one implementation behind both
      # `stockerly:seed_assets` and `db/seeds.rb` — they used to carry a copy of
      # the list each, and the copies drifted.
      class SeedCatalog < SimpleUseCase
        def call
          created = 0
          corrected = 0
          skipped = []

          Domain::AssetCatalog.seedable.each do |attrs|
            asset = Asset.find_or_create_by!(symbol: attrs[:symbol]) do |record|
              apply(record, attrs)
              created += 1
            end

            fixes = corrections_for(asset, attrs, skipped)
            next if fixes.empty?

            asset.update!(fixes)
            corrected += 1
          end

          { created: created, corrected: corrected, skipped: skipped, total: Asset.count }
        end

        private

        def apply(record, attrs)
          attrs.except(:symbol).each { |key, value| record.send(:"#{key}=", value) }
          record.logo_url = logo_for(attrs)
        end

        def corrections_for(asset, attrs, skipped)
          fixes = {}
          fixes[:country] = attrs[:country] if attrs[:country].present? && asset.country.blank?

          logo = logo_for(attrs)
          fixes[:logo_url] = logo if logo.present? && asset.logo_url.blank?

          # Currency decides what money on this asset means, so it is only safe
          # to correct while nothing has been traded against it. MX rows never
          # declared one and were all created with the column default.
          if attrs[:currency].present? && asset.currency != attrs[:currency]
            asset.trades.exists? ? skipped << asset.symbol : fixes[:currency] = attrs[:currency]
          end

          fixes
        end

        def logo_for(attrs)
          Domain::AssetCatalog.logo_url_for(
            symbol: attrs[:symbol], asset_type: attrs[:asset_type], country: attrs[:country]
          )
        end
      end
    end
  end
end
