module Assistant
  module Capabilities
    # The Señales screen's list, in its own phrases. What the owner holds is in
    # it only while the holdings switch is on.
    class RecentSignals < Capability
      MAX_CHARS = 1_500

      declare "signals.recent",
              description: "The Señales screen: indicator signals of the last #{Trading::UseCases::LoadSignals::WINDOW_DAYS} days " \
                           "(RSI zones, moving-average crosses, Bollinger breaches) for what the user watches, and for what " \
                           "they hold when holdings are shared, newest first, each with its asset and date."

      def cards
        readings = Trading::Queries::Signals.call(include_held: @registry.holdings?)
        return [] if readings.empty?

        lines = readings.map do |row|
          detail = [ row[:reading], ("RSI #{row[:rsi]}" if row[:rsi]) ].compact.join(" · ")
          held = I18n.t("assistant.cards.la_tienes") if row[:held]
          "#{[ InstrumentLabel.short(row[:symbol]), held ].compact.join(' ')} (#{I18n.l(row[:observed_at].to_date, format: :short)}): #{detail}"
        end
        [ card(kind: "signals", title: I18n.t("assistant.cards.senales", count: Trading::UseCases::LoadSignals::WINDOW_DAYS),
               body: lines.join("; ")) ]
      end
    end
  end
end
