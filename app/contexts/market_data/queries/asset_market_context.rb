module MarketData
  module Queries
    # Public read API for the asset detail's "Contexto de mercado" block: the
    # reference index, whether its market is open, the matching Fear & Greed
    # reading, and how the asset moved against its index today.
    #
    # ADR-014: the divergence is returned as a symbol, never as prose. Which
    # phrase a reading is entitled to is a decision, and it belongs in the
    # locale rather than in a template building sentences from numbers.
    class AssetMarketContext
      # A move is only worth calling out once the two differ by more than this.
      # Calibrated against the artboard's own example — it reads -3.0% index
      # against -2.1% asset as market-led, so the threshold has to sit below
      # that 0.9 gap rather than above it.
      DIVERGENCE_THRESHOLD = 0.5

      # `day_change` is the computed figure the header renders (ADR-021), passed
      # in so the sentence below the price cannot quote a different number.
      def self.call(asset:, day_change: nil)
        index = reference_index_for(asset)

        {
          index: index,
          market_open: MarketHours.open_for_asset?(asset),
          sentiment: sentiment_for(asset),
          divergence: divergence(day_change, index),
          asset_change: day_change,
          index_change: index&.change_percent
        }
      end

      # Crypto trades against no index, so it gets none rather than a
      # misleading one.
      def self.reference_index_for(asset)
        return nil if asset.asset_type_crypto?

        MarketIndex.find_by(symbol: asset.country == "MX" ? "IPC" : "SPX")
      end
      private_class_method :reference_index_for

      # Only crypto has a sentiment gauge left. Equities keep the index quote
      # and the divergence sentence, which say more about today's move than a
      # market-wide gauge did (D38).
      def self.sentiment_for(asset)
        asset.asset_type_crypto? ? FearGreedReading.latest_crypto : nil
      end
      private_class_method :sentiment_for

      # :market_led  — the index moved further than the asset, in the same
      #                direction: today says more about the market.
      # :asset_led   — the asset moved further, or against the index.
      # :aligned     — the two are within the threshold.
      def self.divergence(asset_change, index)
        index_change = index&.change_percent
        return nil if asset_change.nil? || index_change.nil?

        gap = asset_change.to_f - index_change.to_f
        return :aligned if gap.abs <= DIVERGENCE_THRESHOLD

        index_change.to_f.abs > asset_change.to_f.abs && index_change.to_f * asset_change.to_f > 0 ? :market_led : :asset_led
      end
      private_class_method :divergence
    end
  end
end
