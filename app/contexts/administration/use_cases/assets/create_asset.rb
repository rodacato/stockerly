module Administration
  module UseCases
    module Assets
      class CreateAsset < ApplicationUseCase
        PARQET_LOGO_URL = "https://assets.parqet.com/logos/symbol/%s"
        COINGECKO_LOGO_URL = "https://assets.coingecko.com/coins/images/%s/small/%s.png"
        COINGECKO_IMAGE_IDS = {
          "BTC" => [ 1, "bitcoin" ], "ETH" => [ 279, "ethereum" ], "SOL" => [ 4128, "solana" ],
          "ADA" => [ 975, "cardano" ], "DOT" => [ 12171, "polkadot" ], "DOGE" => [ 5, "dogecoin" ],
          "AVAX" => [ 12559, "avalanche-2" ], "LINK" => [ 877, "chainlink" ], "UNI" => [ 12504, "uniswap" ]
        }.freeze

        def call(admin:, params:)
          attrs = yield validate(Administration::Contracts::Assets::CreateContract, params)
          attrs = resolve_logo_url(attrs)
          attrs = resolve_data_source(attrs)
          asset = yield persist(attrs)
          _     = yield publish(MarketData::Events::AssetCreated.new(
            asset_id: asset.id,
            symbol: asset.symbol,
            admin_id: admin.id
          ))

          Success(asset)
        end

        private

        def resolve_logo_url(attrs)
          return attrs if attrs[:logo_url].present?

          logo = case attrs[:asset_type]
          when "crypto"
                   ids = COINGECKO_IMAGE_IDS[attrs[:symbol].upcase]
                   ids ? format(COINGECKO_LOGO_URL, ids[0], ids[1]) : nil
          when "fixed_income"
                   nil
          else
                   attrs[:country] == "MX" ? nil : format(PARQET_LOGO_URL, attrs[:symbol])
          end

          attrs.merge(logo_url: logo)
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
