module Assistant
  module Domain
    # The screen's symbol as cards, chosen by what the question names. Figures
    # are formatted here, once, so the prose can only repeat them (ADR-031 §2).
    module SymbolCards
      ASKS = {
        quote: /\b(precio|cotiza|cuesta|vale|hoy|como va)\b/,
        range: /\b(rango|maximo|minimo|ano|52)\b/,
        headlines: /\b(titular|titulares|noticia|noticias|publicad)/
      }.freeze

      def self.call(brief:, question:, glossary_keys: [])
        text = Glossary.normalise(question)
        cards = []
        cards << quote(brief) if brief[:quote] && text.match?(ASKS[:quote])
        cards << range(brief) if brief[:range_52w] && text.match?(ASKS[:range])
        cards.concat(readings(brief, glossary_keys))
        cards << headlines(brief) if brief[:headlines].present? && text.match?(ASKS[:headlines])
        cards << quote(brief) if cards.empty? && brief[:quote]
        cards
      end

      def self.quote(brief)
        q = brief[:quote]
        change = q[:day_change_percent] && format("%+.1f%%", q[:day_change_percent])
        Card.new(kind: "quote", title: "#{brief[:symbol]} · #{brief[:name]}",
                 body: (I18n.t("assistant.cards.cambio_del_dia", change: change) if change),
                 figure: "#{brief[:currency]} #{money(q[:price])}",
                 source: [ q[:source], q[:quoted_at] && I18n.l(q[:quoted_at].to_date, format: :long) ].compact.join(" · "))
      end

      def self.range(brief)
        r = brief[:range_52w]
        Card.new(kind: "range", title: I18n.t("assistant.cards.rango", symbol: brief[:symbol]),
                 body: I18n.t("assistant.cards.rango_cuerpo", low: "#{brief[:currency]} #{money(r[:low])}", high: "#{brief[:currency]} #{money(r[:high])}"),
                 figure: nil, source: nil)
      end

      def self.readings(brief, glossary_keys)
        rows = brief.dig(:reading, :rows).to_a.select { |row| glossary_keys.include?(row[:indicator].to_s) }
        rows.map do |row|
          Card.new(kind: "reading", title: "#{I18n.t("market.glosario.#{row[:indicator]}.nombre")} · #{brief[:symbol]}",
                   body: I18n.t("market.signals.#{row[:indicator]}.#{row[:state]}"), figure: reading_figure(row),
                   source: I18n.t("assistant.cards.lectura_del", date: I18n.l(brief.dig(:reading, :calculated_at).to_date, format: :long)))
        end
      end

      def self.headlines(brief)
        titles = brief[:headlines].map { |item| "«#{item[:title]}» (#{item[:source]}, #{I18n.l(item[:published_at].to_date, format: :long)})" }
        Card.new(kind: "headlines", title: I18n.t("assistant.cards.titulares", symbol: brief[:symbol]),
                 body: titles.join(" "), figure: nil, source: nil)
      end

      def self.reading_figure(row)
        case row[:indicator].to_s
        when "moving_average" then [ row[:ma50] && "MA50 #{money(row[:ma50])}", row[:ma200] && "MA200 #{money(row[:ma200])}" ].compact.join(" · ")
        when "bollinger" then "#{money(row[:lower])} – #{money(row[:upper])}"
        when "atr" then format("%.1f%%", row[:value])
        else row[:value] && format("%.1f", row[:value])
        end
      end

      def self.money(value) = ActiveSupport::NumberHelper.number_to_delimited(format("%.2f", value))

      private_class_method :quote, :range, :readings, :headlines, :reading_figure, :money
    end
  end
end
