module Assistant
  module Capabilities
    # What the asset's indicators did recently, in the page's own phrases.
    class AssetObservations < Capability
      declare "asset.observations", required: %i[symbol],
                                    description: "What an asset's indicators did in the last 30 days: RSI zone entries and exits, moving-average crosses, Bollinger breaches, with dates."

      def cards(symbol:)
        data = MarketData::Queries::AssetObservations.call(symbol: symbol)
        return [] if data.nil? || data[:observations].empty?

        lines = data[:observations].map { |row| "#{long_date(row[:observed_at])}: #{row[:reading]}" }
        [ card(kind: "observations", title: I18n.t("assistant.cards.observaciones", symbol: data[:symbol]), body: lines.join("; ")) ]
      end
    end
  end
end
