module MarketData
  module Domain
    # Generates AI narrative from earnings history — beat/miss pattern analysis.
    # Strictly observational — no buy/sell recommendations.
    class EarningsNarrativeGenerator
      include Dry::Monads[:result]

      MIN_EVENTS = 2

      SYSTEM_PROMPT = <<~PROMPT.freeze
        You are a financial analyst. Provide strictly observational analysis of earnings history.
        Never recommend buying, selling, or any specific action.
        Respond ONLY with valid JSON: {"narrative": "...", "pattern": "consistent|improving|declining|mixed", "consistency_score": 75}
        consistency_score must be 0-100. Keep narrative under 500 characters.
      PROMPT

      def self.generate(asset:, earnings_events:, gateway: nil)
        new(gateway: gateway).generate(asset: asset, earnings_events: earnings_events)
      end

      def initialize(gateway: nil)
        @gateway = gateway || Gateways::LlmGateway.new
      end

      def generate(asset:, earnings_events:)
        events = earnings_events.to_a
        return Failure([ :insufficient_data, "Need at least #{MIN_EVENTS} earnings events" ]) if events.size < MIN_EVENTS

        prompt = build_prompt(asset.symbol, events)
        result = @gateway.complete(prompt: prompt, system_prompt: SYSTEM_PROMPT, max_tokens: 500)
        return result if result.failure?

        parse_and_validate(result.value![:content])
      end

      private

      def build_prompt(symbol, events)
        lines = [ "Analyze earnings history for #{symbol}:" ]
        events.each do |e|
          estimated = e.estimated_eps || "N/A"
          actual = e.actual_eps || "pending"
          beat = if e.actual_eps && e.estimated_eps
            e.actual_eps > e.estimated_eps ? "beat" : "miss"
          else
            "N/A"
          end
          lines << "- #{e.report_date}: Est #{estimated}, Actual #{actual} (#{beat})"
        end
        lines.join("\n")
      end

      def parse_and_validate(content)
        parsed = JSON.parse(content).symbolize_keys
        parsed[:consistency_score] = parsed[:consistency_score].to_i.clamp(0, 100)

        contract = Contracts::NarrativeResponseContract.new
        validation = contract.call(parsed)

        if validation.success?
          Success({
            narrative: parsed[:narrative],
            pattern: parsed[:pattern],
            consistency_score: parsed[:consistency_score],
            generated_at: Time.current
          })
        else
          Failure([ :validation_error, validation.errors.to_h ])
        end
      rescue JSON::ParserError
        Failure([ :parse_error, "Invalid JSON response from LLM" ])
      end
    end
  end
end
