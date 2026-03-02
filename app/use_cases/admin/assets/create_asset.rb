module Admin
  module Assets
    class CreateAsset < ApplicationUseCase
      SYNTH_LOGO_URL = "https://logo.synthfinance.com/ticker/%s"
      COINGECKO_LOGO_URL = "https://assets.coingecko.com/coins/images/%s/small/%s.png"
      COINGECKO_IMAGE_IDS = {
        "BTC" => [ 1, "bitcoin" ], "ETH" => [ 279, "ethereum" ], "SOL" => [ 4128, "solana" ],
        "ADA" => [ 975, "cardano" ], "DOT" => [ 12171, "polkadot" ], "DOGE" => [ 5, "dogecoin" ],
        "AVAX" => [ 12559, "avalanche-2" ], "LINK" => [ 877, "chainlink" ], "UNI" => [ 12504, "uniswap" ]
      }.freeze

      def call(admin:, params:)
        attrs = yield validate(Admin::Assets::CreateContract, params)
        attrs = resolve_logo_url(attrs)
        attrs = resolve_data_source(attrs)
        asset = yield persist(attrs)
        _     = yield publish(MarketData::AssetCreated.new(
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
        else
                 format(SYNTH_LOGO_URL, attrs[:symbol])
        end

        attrs.merge(logo_url: logo)
      end

      def resolve_data_source(attrs)
        source = if attrs[:country] == "MX"
                   "Yahoo Finance"
        elsif attrs[:asset_type] == "crypto"
                   "CoinGecko API"
        else
                   "Polygon.io"
        end

        attrs.merge(data_source: source)
      end

      def persist(attrs)
        asset = Asset.new(attrs.merge(sync_status: :active))
        asset.save ? Success(asset) : Failure([ :validation, asset.errors.to_hash ])
      end
    end
  end
end
