module Assistant
  module Domain
    # Chooses capabilities without a model; the registry does the reading.
    module ContextSelector
      ASKS = {
        quote: /\b(precio|cotiza|cuesta|vale|hoy|como va)\b/,
        range: /\b(rango|maximo|minimo|ano|52)\b/,
        indicators: /\b(indicador|indicadores|tecnic[oa]s?|senal|senales)\b/,
        fundamentals: /\b(fundamentales?|empresa|financier[oa]s?|finanzas|salud|deuda|margen(es)?|rentabilidad|valuacion|utilidad(es)?)\b/,
        observations: /\b(observacion(es)?|que paso|que ha pasado|recientes?|cruz[oó]|esta semana)\b/,
        headlines: /\b(titular|titulares|noticia|noticias|publicad)/
      }.freeze

      def self.call(question:, symbol: nil)
        registry = Capabilities::Registry.new
        run = registry.method(:cards)

        entries = Glossary.matching(question)
        cards = run.call(entries.map { |entry| [ "glossary.define", { term: entry.key } ] })
        return cards if symbol.blank?

        asset_cards = run.call(asset_plan(Glossary.normalise(question), symbol, entries.map(&:key)))
        asset_cards = run.call([ [ "asset.quote", { symbol: symbol } ] ]) if asset_cards.empty?
        cards + asset_cards
      end

      def self.asset_plan(text, symbol, glossary_keys)
        steps = []
        steps << [ "asset.quote", { symbol: symbol } ] if text.match?(ASKS[:quote])
        steps << [ "asset.range", { symbol: symbol } ] if text.match?(ASKS[:range])
        steps << named_or_all("asset.indicators", symbol, text.match?(ASKS[:indicators]), glossary_keys)
        steps << named_or_all("asset.fundamentals", symbol, text.match?(ASKS[:fundamentals]), glossary_keys)
        steps << [ "asset.observations", { symbol: symbol } ] if text.match?(ASKS[:observations])
        steps << [ "asset.news", { symbol: symbol } ] if text.match?(ASKS[:headlines])
        steps.compact
      end

      # Asked for as a whole, it reads everything; a term the question named narrows it to that row.
      def self.named_or_all(name, symbol, asked, glossary_keys)
        return [ name, { symbol: symbol } ] if asked

        [ name, { symbol: symbol, only: glossary_keys } ] if glossary_keys.any?
      end

      private_class_method :asset_plan, :named_or_all
    end
  end
end
