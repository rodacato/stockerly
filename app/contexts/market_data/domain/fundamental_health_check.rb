module MarketData
  module Domain
    # AI-powered fundamental health analysis for an asset.
    # Strictly observational — no buy/sell recommendations.
    class FundamentalHealthCheck
      include Dry::Monads[:result]

      SYSTEM_PROMPT = <<~PROMPT.freeze
        You are a financial analyst. Provide strictly observational analysis of financial health.
        Never recommend buying, selling, or any specific action.
        Respond ONLY with valid JSON: {"health_score": 75, "strengths": ["..."], "concerns": ["..."], "summary": "..."}
        health_score must be 0-100. Max 4 strengths and 4 concerns.
      PROMPT

      METRIC_KEYS = %w[eps pe_ratio debt_to_equity revenue_growth profit_margin return_on_equity beta].freeze

      def self.analyze(asset:, fundamental:, gateway: nil)
        new(gateway: gateway).analyze(asset: asset, fundamental: fundamental)
      end

      def initialize(gateway: nil)
        @gateway = gateway || Gateways::LlmGateway.new
      end

      def analyze(asset:, fundamental:)
        return Failure([ :no_fundamentals, "No fundamental data available" ]) unless fundamental

        metrics = extract_metrics(fundamental)
        prompt = build_prompt(asset.symbol, metrics)

        result = @gateway.complete(prompt: prompt, system_prompt: SYSTEM_PROMPT, max_tokens: 600)
        return result if result.failure?

        parse_and_validate(result.value![:content])
      end

      private

      def extract_metrics(fundamental)
        data = fundamental.metrics || {}
        METRIC_KEYS.each_with_object({}) do |key, hash|
          hash[key] = data[key] if data[key].present?
        end
      end

      def build_prompt(symbol, metrics)
        lines = [ "Analyze financial health for #{symbol}:" ]
        metrics.each { |key, value| lines << "- #{key.humanize}: #{value}" }
        lines.join("\n")
      end

      def parse_and_validate(content)
        parsed = JSON.parse(content).symbolize_keys
        parsed[:health_score] = parsed[:health_score].to_i.clamp(0, 100)

        contract = Contracts::HealthCheckResponseContract.new
        validation = contract.call(parsed)

        if validation.success?
          Success({
            health_score: parsed[:health_score],
            strengths: parsed[:strengths],
            concerns: parsed[:concerns],
            summary: parsed[:summary],
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
