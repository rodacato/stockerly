module Assistant
  module Domain
    # Which cards a question gets, decided without a model (no planner in v0):
    # the glossary terms it names, then the screen's symbol where it asks for it.
    module ContextSelector
      def self.call(question:, symbol: nil)
        entries = Glossary.matching(question)
        cards = entries.map { |entry| Card.new(kind: "glossary", title: entry.name, body: entry.body, figure: nil, source: I18n.t("assistant.cards.glosario")) }
        brief = symbol.present? ? MarketData::Queries::AssetBrief.call(symbol: symbol) : nil
        cards += SymbolCards.call(brief: brief, question: question, glossary_keys: entries.map(&:key)) if brief
        cards
      end
    end
  end
end
