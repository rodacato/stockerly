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
        only: "only: optional list of indicator or metric keys to narrow to",
        date: "date: optional day the question asks about, as YYYY-MM-DD"
      }.freeze

      INSTRUCTIONS = <<~TEXT.freeze
        You choose which of Stockerly's data to read so another step can answer the user's question.
        Never answer the question. Reply with only a JSON array, no prose and no code fence, where each
        element is {"read": "<name>", ...inputs}. Prefer fewer reads. Use glossary.define for each
        financial term the question asks about. If the question names no symbol and a screen symbol is
        given, the question is about that symbol, unless it asks about the user's own holdings as a
        whole. A question about what the user holds, owns or has gained uses the portfolio reads when
        they are listed. A question about what is on the user's screen without naming it ("these",
        "here", "which ones") uses the reads that show that screen. Earlier questions, when given, only
        say what a short follow-up refers to. If
        nothing below holds what it needs, reply [].
      TEXT

      def self.system(symbol, screen: nil, holdings: false)
        lines = Capabilities::Registry.available(holdings: holdings).values.map do |capability|
          inputs = (capability.required + capability.optional).map { |input| INPUTS.fetch(input) }
          "- #{capability.name_in_registry}: #{capability.description} Inputs: #{inputs.join('; ').presence || 'none'}."
        end
        where = Screens.described(screen)&.then { |text| "\nUser's screen: #{text}" }
        on_symbol = symbol.present? ? "\nScreen symbol: #{symbol}." : ""
        "#{INSTRUCTIONS}\nToday: #{Date.current.iso8601}.\nAvailable reads:\n#{lines.join("\n")}#{where}#{on_symbol}"
      end

      # Anything but a JSON array of objects is no plan; the caller falls back.
      def self.steps(reply, holdings: false)
        listed = Capabilities::Registry.available(holdings: holdings)
        known, unknown = parse(reply).partition { |read| listed.key?(read["read"]) }
        Rails.logger.info("[assistant] planner named outside the registry: #{unknown.pluck("read").inspect}") if unknown.any?

        known.map { |read| [ read["read"], input(listed.fetch(read["read"]), read) ] }.uniq.first(MAX_STEPS)
      end

      def self.parse(reply)
        text = reply.to_s
        first, last = text.index("["), text.rindex("]")
        reads = JSON.parse(text[first..last]) if first && last && first < last
        reads.is_a?(Array) ? reads.grep(Hash) : []
      rescue JSON::ParserError
        []
      end

      def self.input(capability, read)
        read.slice(*(capability.required + capability.optional).map(&:to_s)).to_h do |key, value|
          value = key == "only" ? Array(value).map { |item| item.to_s.first(40) }.first(10) : value.to_s.strip.first(MAX_INPUT)
          [ key.to_sym, key == "symbol" ? value.upcase : value ]
        end
      end

      private_class_method :parse, :input
    end
  end
end
