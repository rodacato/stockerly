module Assistant
  module Domain
    # Stockerly's own definitions, gathered from the three catalogues the screens
    # already explain terms with. ADR-031 §2: the assistant defines nothing from
    # its own training, so a term absent here is a term it cannot explain.
    module Glossary
      Entry = Data.define(:key, :name, :body, :terms)

      # Names readers use that the catalogue's own name does not contain.
      ALIASES = {
        "moving_average" => [ "ma", "sma", "ema", "media movil", "promedio movil", "ma50", "ma200" ],
        "bollinger" => [ "bandas" ],
        "vs_cetes" => [ "vs cetes", "contra cetes" ],
        "total_liabilities_net_minority_interest" => [ "pasivos", "pasivo total" ],
        "pe_ratio" => [ "p/e", "per" ]
      }.freeze

      def self.entries
        glosario = I18n.t("market.glosario").map { |key, entry| build(key, entry[:nombre], "#{entry[:desc]} #{entry[:guia]}") }
        metricas = I18n.t("market.metricas").map { |key, entry| build(key, entry[:nombre], "#{entry[:desc]} #{entry[:guia]}") }
        ayuda = I18n.t("dashboard.ayuda").except(:cerrar, :explicar).map { |key, entry| build(key, entry[:titulo], entry[:cuerpo]) }
        (glosario + metricas + ayuda).uniq(&:key)
      end

      def self.matching(question, limit: 3)
        text = " #{normalise(question)} "
        entries.select { |entry| entry.terms.any? { |term| text.match?(/[^a-z0-9]#{Regexp.escape(term)}[^a-z0-9]/) } }.first(limit)
      end

      def self.build(key, name, body)
        short = name.to_s.sub(/\s*\(.*\)\z/, "")
        terms = ([ name, short ] + ALIASES.fetch(key.to_s, [])).map { |term| normalise(term) }.uniq
        Entry.new(key: key.to_s, name: name, body: body.squish, terms: terms)
      end

      def self.normalise(text) = I18n.transliterate(text.to_s).downcase.squish

      private_class_method :build
    end
  end
end
