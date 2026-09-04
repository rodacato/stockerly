module MarketData
  module UseCases
    # One home for the fundamentals row two syncs write: Alpha Vantage one
    # equity per call, CoinGecko every crypto in a single one.
    class StoreFundamentals < SimpleUseCase
      # LoadAssetDetail reads a different row per asset type, so the wrong
      # label here stores data the screen never looks at.
      EQUITY = "OVERVIEW".freeze
      CRYPTO = "CRYPTO_MARKET".freeze

      def call(asset:, metrics:, period_label: EQUITY)
        data = metrics.dup
        source = data.delete(:data_source) || "unknown"

        AssetFundamental
          .find_or_initialize_by(asset: asset, period_label: period_label)
          .update!(metrics: data, source: source, calculated_at: Time.current)

        asset.update!(fundamentals_synced_at: Time.current)

        EventBus.publish(MarketData::Events::AssetFundamentalsUpdated.new(
          asset_id: asset.id, symbol: asset.symbol, source: source
        ))
      end
    end
  end
end
