module MarketData
  module Queries
    # ADR-031: the major indices and the crypto sentiment as plain data. A
    # sentiment reading past its freshness window is not today's, so it is nil.
    class MarketPulse
      # @api public
      def self.call
        { indices: indices, crypto_sentiment: crypto_sentiment }.freeze
      end

      def self.indices
        MarketIndex.major.where.not(value: nil).map do |index|
          { symbol: index.symbol, name: index.name, value: index.value, change_percent: index.change_percent,
            open: index.is_open, as_of: index.updated_at }.freeze
        end.freeze
      end

      def self.crypto_sentiment
        reading = FearGreedReading.latest_crypto
        return nil unless reading

        { value: reading.value, classification: reading.classification.parameterize(separator: "_"),
          source: reading.source, as_of: reading.fetched_at }.freeze
      end
      private_class_method :indices, :crypto_sentiment
    end
  end
end
