module Assistant
  module Capabilities
    # The latest auction yield per CETES term, each with its own auction date.
    class CetesCurve < Capability
      declare "cetes.curve",
              description: "The latest Banxico auction yield of CETES at 28, 91, 182 and 364 days, with each auction's date."

      def cards
        terms = MarketData::Queries::CetesCurve.call
        return [] if terms.empty?

        lines = terms.map do |row|
          I18n.t("assistant.cards.cetes_plazo", dias: row[:term], rate: format("%.2f", row[:yield_rate]), date: long_date(row[:auction_date]))
        end
        [ card(kind: "cetes", title: I18n.t("assistant.cards.cetes"), body: lines.join(" · "), source: "Banxico") ]
      end
    end
  end
end
