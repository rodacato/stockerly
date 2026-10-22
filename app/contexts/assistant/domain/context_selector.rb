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
        headlines: /\b(titular|titulares|noticia|noticias|publicad)/,
        earnings: /\b(reporte|reporta|reportes|resultados|earnings|upa)\b/
      }.freeze

      MARKET_ASKS = {
        "market.pulse" => /\b(mercados?|indices?|bolsa|sentimiento|miedo|codicia|fear|greed)\b/,
        "fx.rate" => /\b(dolar|tipo de cambio|usd)\b/,
        "cetes.curve" => /\bcetes?\b/
      }.freeze

      MINE = /\b(mi|mis|mio|mia|mios|mias|tengo|llevo|portafolio|cartera|posicion|posiciones|gane|ganado|perdido)\b/
      COMING = /\b(vence|vencen|vencimientos?|proxim[oa]s?|viene|vienen)\b/

      def self.call(question:, symbol: nil, holdings: false, screen: nil)
        run = Capabilities::Registry.new(holdings: holdings).method(:cards)

        entries = Glossary.matching(question)
        text = Glossary.normalise(question)
        cards = run.call(entries.map { |entry| [ "glossary.define", { term: entry.key } ] })
        market_cards = run.call(MARKET_ASKS.filter_map { |name, ask| [ name, {} ] if text.match?(ask) })
        mine_cards = holdings ? run.call(mine_plan(text, symbol)) : []
        if symbol.blank?
          found = cards + market_cards + mine_cards
          return found.presence || run.call(Screens.reads(screen))
        end

        asset_cards = run.call(asset_plan(text, symbol, entries.map(&:key)))
        asset_cards = run.call([ [ "asset.quote", { symbol: symbol } ] ]) if (asset_cards + market_cards + mine_cards).empty?
        cards + market_cards + mine_cards + asset_cards
      end

      # On an asset's screen "lo mío" is that position; anywhere else, the portfolio.
      def self.mine_plan(text, symbol)
        steps = []
        steps << [ "portfolio.positions", symbol.present? ? { symbol: symbol } : {} ] if text.match?(MINE)
        steps << [ "portfolio.events", {} ] if text.match?(COMING) || (text.match?(MINE) && text.match?(ASKS[:earnings]))
        steps
      end

      def self.asset_plan(text, symbol, glossary_keys)
        steps = []
        steps << [ "asset.quote", { symbol: symbol } ] if text.match?(ASKS[:quote])
        steps << [ "asset.range", { symbol: symbol } ] if text.match?(ASKS[:range])
        steps << named_or_all("asset.indicators", symbol, text.match?(ASKS[:indicators]), glossary_keys)
        steps << named_or_all("asset.fundamentals", symbol, text.match?(ASKS[:fundamentals]), glossary_keys)
        steps << [ "asset.observations", { symbol: symbol } ] if text.match?(ASKS[:observations])
        steps << [ "asset.news", { symbol: symbol } ] if text.match?(ASKS[:headlines])
        steps << [ "asset.earnings", { symbol: symbol } ] if text.match?(ASKS[:earnings])
        steps.compact
      end

      # Asked for as a whole, it reads everything; a term the question named narrows it to that row.
      def self.named_or_all(name, symbol, asked, glossary_keys)
        return [ name, { symbol: symbol } ] if asked

        [ name, { symbol: symbol, only: glossary_keys } ] if glossary_keys.any?
      end

      private_class_method :mine_plan, :asset_plan, :named_or_all
    end
  end
end
