module Assistant
  module Capabilities
    # When an asset reports next, and how its last report compared with the estimate.
    class AssetEarnings < Capability
      declare "asset.earnings", required: %i[symbol],
                                description: "An asset's next earnings report date and timing, and its last reported earnings per share against the estimate."

      def cards(symbol:)
        data = MarketData::Queries::AssetEarnings.call(symbol: symbol)
        return [] if data.nil? || (data[:next].nil? && data[:last].nil?)

        lines = [ upcoming(data[:next]), reported(data[:last]) ].compact
        [ card(kind: "earnings", title: I18n.t("assistant.cards.resultados", symbol: data[:symbol]), body: lines.join(" · ")) ]
      end

      private

      def upcoming(event)
        return unless event

        timing = event[:timing] == "after_market_close" ? I18n.t("assistant.cards.despues_del_cierre") : I18n.t("assistant.cards.antes_de_la_apertura")
        I18n.t("assistant.cards.proximo_reporte", date: long_date(event[:report_date]), timing: timing)
      end

      def reported(event)
        return unless event

        date = long_date(event[:report_date])
        actual = format("%.2f", event[:actual_eps])
        return I18n.t("assistant.cards.ultimo_reporte", date: date, actual: actual) unless event[:estimated_eps]

        I18n.t("assistant.cards.ultimo_reporte_vs", date: date, actual: actual, estimated: format("%.2f", event[:estimated_eps]))
      end
    end
  end
end
