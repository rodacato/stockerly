module Assistant
  module Domain
    # What a model may choose from, and what of its choice survives: only
    # registry names, only declared inputs, at most MAX_STEPS (plan §4, G2).
    module Planner
      MAX_STEPS = 6
      MAX_INPUT = 120

      INPUTS = {
        symbol: "symbol: the ticker as Stockerly lists it (NVDA, AMX, BTC)",
        term: "term: the term to define, as the user wrote it",
        only: "only: optional list of indicator or metric keys to narrow to"
      }.freeze

      INSTRUCTIONS = <<~TEXT.freeze
        You choose which of Stockerly's data to read so another step can answer the user's question.
        Never answer the question. Reply with only a JSON array, no prose and no code fence, where each
        element is {"read": "<name>", ...inputs}. Prefer fewer reads. Use glossary.define for each
        financial term the question asks about. If the question names no symbol and a screen symbol is
        given, the question is about that symbol. If nothing below holds what it needs, reply [].
      TEXT

      def self.system(symbol)
        lines = Capabilities::Registry::CAPABILITIES.values.map do |capability|
          inputs = (capability.required + capability.optional).map { |input| INPUTS.fetch(input) }
          "- #{capability.name_in_registry}: #{capability.description} Inputs: #{inputs.join('; ')}."
        end
        screen = symbol.present? ? "\nScreen symbol: #{symbol}." : ""
        "#{INSTRUCTIONS}\nAvailable reads:\n#{lines.join("\n")}#{screen}"
      end

      # Anything but a JSON array of objects is no plan; the caller falls back.
      def self.steps(reply)
        reads = parse(reply)
        known, unknown = reads.partition { |read| Capabilities::Registry::CAPABILITIES.key?(read["read"]) }
        Rails.logger.info("[assistant] planner named outside the registry: #{unknown.pluck("read").inspect}") if unknown.any?

        known.map { |read| [ read["read"], input(read) ] }.uniq.first(MAX_STEPS)
      end

      def self.parse(reply)
        array = reply.to_s[/\[.*\]/m]
        reads = array && JSON.parse(array)
        reads.is_a?(Array) ? reads.grep(Hash) : []
      rescue JSON::ParserError
        []
      end

      def self.input(read)
        read.slice("symbol", "term", "only").to_h do |key, value|
          value = key == "only" ? Array(value).map { |item| item.to_s.first(40) }.first(10) : value.to_s.strip.first(MAX_INPUT)
          [ key.to_sym, key == "symbol" ? value.upcase : value ]
        end
      end

      private_class_method :parse, :input
    end
  end
end
