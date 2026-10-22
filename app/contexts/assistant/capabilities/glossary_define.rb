module Assistant
  module Capabilities
    # Stockerly's own definition of a term. ADR-031 §2: the assistant defines
    # nothing from its training, so a term absent here cannot be explained.
    class GlossaryDefine < Capability
      declare "glossary.define", required: %i[term],
                                 description: "Stockerly's own definition of a financial term, indicator, metric or statement line."

      def cards(term:)
        entry = Domain::Glossary.entries.find { |candidate| candidate.key == term.to_s } || Domain::Glossary.matching(term.to_s, limit: 1).first
        return [] unless entry

        [ card(kind: "glossary", title: entry.name, body: entry.body, source: I18n.t("assistant.cards.glosario")) ]
      end
    end
  end
end
