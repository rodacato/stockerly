module MarketData
  module Domain
    # Generates AI-powered portfolio insight from anonymized portfolio data.
    # Strictly observational — no buy/sell recommendations.
    class InsightGenerator
      include Dry::Monads[:result]

      SYSTEM_PROMPT = <<~PROMPT.freeze
        You are a financial analyst providing strictly observational analysis.
        Never recommend buying, selling, or any specific action.
        Respond ONLY with valid JSON in this exact format:
        {"summary": "...", "observations": ["..."], "risk_factors": ["..."]}
        Keep summary under 500 characters. Max 5 observations and 3 risk factors.
      PROMPT

      def self.generate(portfolio_data:, gateway: nil)
        new(gateway: gateway).generate(portfolio_data: portfolio_data)
      end

      def initialize(gateway: nil)
        @gateway = gateway || Gateways::LlmGateway.new
      end

      def generate(portfolio_data:)
        prompt = build_prompt(portfolio_data)
        result = @gateway.complete(prompt: prompt, system_prompt: SYSTEM_PROMPT, max_tokens: 800)

        return result if result.failure?

        parse_and_validate(result.value![:content], result.value!)
      end

      private

      def build_prompt(data)
        parts = [ "Analyze this portfolio snapshot:" ]
        parts << "- #{data[:position_count]} positions" if data[:position_count]
        parts << "- Weekly change: #{data[:weekly_change]}%" if data[:weekly_change]
        parts << "- Top performer: #{data[:top_performer][:symbol]} (#{data[:top_performer][:change_percent]}%)" if data[:top_performer]
        parts << "- Worst performer: #{data[:worst_performer][:symbol]} (#{data[:worst_performer][:change_percent]}%)" if data[:worst_performer]
        parts << "- Concentration HHI: #{data[:concentration_hhi]} (#{data[:risk_level]})" if data[:concentration_hhi]

        if data[:sector_weights].present?
          weights = data[:sector_weights].map { |s, w| "#{s}: #{w}%" }.join(", ")
          parts << "- Sector weights: #{weights}"
        end

        parts.join("\n")
      end

      def parse_and_validate(content, llm_result)
        parsed = JSON.parse(content).symbolize_keys
        contract = Contracts::InsightResponseContract.new
        validation = contract.call(parsed)

        if validation.success?
          Success({
            summary: parsed[:summary],
            observations: parsed[:observations],
            risk_factors: parsed[:risk_factors] || [],
            provider: llm_result[:provider],
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
