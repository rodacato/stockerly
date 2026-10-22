module Assistant
  module Capabilities
    # USD/MXN on a day, saying which day the rate is really for.
    class ExchangeRate < Capability
      declare "fx.rate", optional: %i[date],
                         description: "The USD/MXN exchange rate today, or in force on a past date, with the date it is for and its publisher (Banxico FIX)."

      def cards(date: nil)
        on = date ? Date.iso8601(date.to_s) : Date.current
        return [] if on > Date.current

        quote = MarketData::Queries::FxQuote.call(date: on)
        return [] unless quote

        [ card(kind: "fx", title: I18n.t("assistant.cards.tipo_de_cambio"), figure: format("%.4f", quote[:rate]),
               body: I18n.t("assistant.cards.tipo_de_cambio_del", date: long_date(quote[:rate_date])), source: quote[:source]) ]
      rescue Date::Error
        []
      end
    end
  end
end
