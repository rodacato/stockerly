module Assistant
  module Capabilities
    # An asset's fundamentals as the asset page prints them, so the card and the
    # screen show the same figure. `only` narrows it to the metrics a question named.
    class AssetFundamentals < Capability
      MAX_CHARS = 900

      declare "asset.fundamentals", required: %i[symbol], optional: %i[only],
                                    description: "An asset's fundamentals: valuation ratios, margins, growth, debt, cash flow, dividends, market cap."

      def cards(symbol:, only: nil)
        data = MarketData::Queries::AssetFundamentals.call(symbol: symbol)
        return [] if data.nil?

        metrics = data[:metrics]
        metrics = metrics.select { |metric| Array(only).map(&:to_s).include?(metric[:key]) } if only
        return [] if metrics.empty?

        [ card(kind: "fundamentals", title: I18n.t("assistant.cards.fundamentales", symbol: data[:symbol]),
               body: metrics.map { |metric| line(metric, data[:currency]) }.join(" · "),
               source: [ data[:source], data[:as_of] && long_date(data[:as_of]) ].compact.join(" · ").presence) ]
      end

      private

      def line(metric, currency)
        "#{I18n.t("market.metricas.#{metric[:key]}.nombre")} #{ApplicationController.helpers.format_metric_value(metric[:value], metric[:unit], currency: currency)}"
      end
    end
  end
end
