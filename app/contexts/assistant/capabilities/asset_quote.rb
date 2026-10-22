module Assistant
  module Capabilities
    # The latest price and day change, formatted once here so the prose can
    # only repeat them.
    class AssetQuote < Capability
      declare "asset.quote", required: %i[symbol],
                             description: "An asset's latest price, its change on the day, when and where it was quoted."

      def cards(symbol:)
        data = brief(symbol)
        quote = data&.dig(:quote)
        return [] unless quote

        change = quote[:day_change_percent] && format("%+.1f%%", quote[:day_change_percent])
        [ card(kind: "quote", title: "#{data[:symbol]} · #{data[:name]}",
               body: (I18n.t("assistant.cards.cambio_del_dia", change: change) if change),
               figure: "#{data[:currency]} #{money(quote[:price])}",
               source: [ quote[:source], quote[:quoted_at] && long_date(quote[:quoted_at]) ].compact.join(" · ")) ]
      end
    end
  end
end
