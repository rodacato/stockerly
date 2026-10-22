module MarketData
  module Queries
    # ADR-031: the fundamentals the asset page lists, as plain data. The same
    # presenter and catalogue render the page, so the two cannot disagree.
    class AssetFundamentals
      extend Domain::SafeDecimal

      # @api public
      def self.call(symbol:)
        asset = AssetLookup.by_symbol(symbol)
        return nil unless asset

        fundamental, fallback = fundamentals_for(asset)

        {
          symbol: asset.symbol,
          name: asset.name,
          currency: asset.currency,
          as_of: fundamental&.calculated_at,
          period_label: fundamental&.period_label,
          source: fundamental&.source,
          metrics: fundamental ? metrics(asset, fundamental, fallback) : []
        }.freeze
      end

      # The page renders no fundamentals for a CETE, whatever rows it carries.
      def self.fundamentals_for(asset)
        asset.asset_type_fixed_income? ? [] : AssetFundamental.for_reading(asset)
      end
      private_class_method :fundamentals_for

      # `unit` is the definition's format_type, which is how FundamentalsHelper#format_metric_value prints it.
      def self.metrics(asset, fundamental, fallback)
        presenter = Domain::FundamentalPresenter.new(asset: asset, fundamental: fundamental, fallback: fallback)

        Domain::MetricDefinitions.shown_for(asset).filter_map do |definition|
          value = safe_decimal(presenter.value(definition.key))
          next if value.nil?

          { key: definition.key.to_s, value: value, unit: definition.format_type }.freeze
        end.freeze
      end
      private_class_method :metrics
    end
  end
end
