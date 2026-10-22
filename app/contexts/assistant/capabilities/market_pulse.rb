module Assistant
  module Capabilities
    # The major indices and the crypto sentiment, as Hoy reads them.
    class MarketPulse < Capability
      declare "market.pulse",
              description: "The major stock indices (IPC, S&P 500, NASDAQ 100, Dow Jones, FTSE 100) with their level, day change and whether the market is open, plus the crypto Fear & Greed reading."

      def cards
        data = MarketData::Queries::MarketPulse.call
        [ indices_card(data[:indices]), sentiment_card(data[:crypto_sentiment]) ].compact
      end

      private

      def indices_card(indices)
        return if indices.empty?

        lines = indices.map do |index|
          change = index[:change_percent] && format("%+.1f%%", index[:change_percent])
          state = I18n.t(index[:open] ? "market.market_context.abierto" : "market.market_context.cerrado")
          "#{index[:name]} #{money(index[:value])} #{change} (#{state})".squish
        end
        card(kind: "market", title: I18n.t("assistant.cards.mercado"), body: lines.join(" · "),
             source: long_date(indices.filter_map { |index| index[:as_of] }.max))
      end

      def sentiment_card(reading)
        return unless reading

        card(kind: "sentiment", title: I18n.t("assistant.cards.fear_greed_cripto"), figure: reading[:value].to_s,
             body: I18n.t("comun.clasificacion.#{reading[:classification]}", default: nil),
             source: "#{reading[:source]} · #{long_date(reading[:as_of])}")
      end
    end
  end
end
