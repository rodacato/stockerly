module Assistant
  module Capabilities
    # The asset's technical reading, one card per indicator, worded by the
    # catalogue the asset page uses (ADR-014). `only` narrows it to the
    # indicators a question named.
    class AssetIndicators < Capability
      MAX_CHARS = 400

      declare "asset.indicators", required: %i[symbol], optional: %i[only],
                                  description: "An asset's latest technical reading: RSI, moving averages, Bollinger bands, ATR, volume — each with its state."

      def cards(symbol:, only: nil)
        data = brief(symbol)
        reading = data&.dig(:reading)
        return [] unless reading

        rows = reading[:rows].to_a
        rows = rows.select { |row| Array(only).map(&:to_s).include?(row[:indicator].to_s) } if only
        rows.map do |row|
          card(kind: "reading", title: "#{I18n.t("market.glosario.#{row[:indicator]}.nombre")} · #{data[:symbol]}",
               body: I18n.t("market.signals.#{row[:indicator]}.#{row[:state]}"), figure: figure(row),
               source: I18n.t("assistant.cards.lectura_del", date: long_date(reading[:calculated_at])))
        end
      end

      private

      def figure(row)
        case row[:indicator].to_s
        when "moving_average" then [ row[:ma50] && "MA50 #{money(row[:ma50])}", row[:ma200] && "MA200 #{money(row[:ma200])}" ].compact.join(" · ")
        when "bollinger" then "#{money(row[:lower])} – #{money(row[:upper])}"
        when "atr" then format("%.1f%%", row[:value])
        else row[:value] && format("%.1f", row[:value])
        end
      end
    end
  end
end
