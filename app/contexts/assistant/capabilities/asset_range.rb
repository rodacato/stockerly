module Assistant
  module Capabilities
    class AssetRange < Capability
      declare "asset.range", required: %i[symbol],
                             description: "An asset's 52-week low and high."

      def cards(symbol:)
        data = brief(symbol)
        range = data&.dig(:range_52w)
        return [] unless range

        low, high = range.values_at(:low, :high).map { |value| "#{data[:currency]} #{money(value)}" }
        [ card(kind: "range", title: I18n.t("assistant.cards.rango", symbol: data[:symbol]),
               body: I18n.t("assistant.cards.rango_cuerpo", low: low, high: high)) ]
      end
    end
  end
end
