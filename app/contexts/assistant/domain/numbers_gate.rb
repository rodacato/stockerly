module Assistant
  module Domain
    # ADR-031 §2: an answer may only state figures its retrieved context holds.
    # Numbers spelled out in words are not seen — a known gap, not a guarantee.
    class NumbersGate
      Result = Data.define(:invented) do
        def ok? = invented.empty?
      end

      CITATION = /\[\d+\]/
      NUMERAL = /\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:[.,]\d+)?/

      def self.call(answer:, context:)
        allowed = numerals(context)
        Result.new(invented: numerals(answer).reject { |n| allowed.include?(n) }.uniq)
      end

      def self.numerals(text)
        text.to_s.gsub(CITATION, " ").scan(NUMERAL).map { |raw| normalise(raw) }
      end

      def self.normalise(raw)
        digits = raw.match?(/,\d{3}(?!\d)/) ? raw.delete(",") : raw.tr(",", ".")
        BigDecimal(digits).to_s("F").delete_suffix(".0")
      end
      private_class_method :numerals, :normalise
    end
  end
end
