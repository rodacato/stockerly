module Assistant
  module Capabilities
    # What is coming for the owner's holdings: the dates Hoy announces, over a month.
    class PortfolioEvents < Capability
      declare "portfolio.events", holdings: true,
                                  description: "What is coming in the next #{Trading::Queries::HoldingEvents::DAYS} days for what the user " \
                                               "holds: fixed-income maturities and earnings reports, each with its date."

      def cards
        events = Trading::Queries::HoldingEvents.call
        return [] if events.empty?

        lines = events.map do |event|
          I18n.t("assistant.cards.evento.#{event[:kind]}", label: InstrumentLabel.short(event[:symbol]), date: long_date(event[:date]),
                                                           days: I18n.t("assistant.cards.en_dias", count: event[:days]))
        end
        [ card(kind: "events", title: I18n.t("assistant.cards.lo_tuyo_proximo", days: Trading::Queries::HoldingEvents::DAYS), body: lines.join(" · ")) ]
      end
    end
  end
end
