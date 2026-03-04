module MarketData
  module Domain
    # Analyzes sentiment for a batch of news articles using LLM.
    # Returns bullish/bearish/neutral with confidence score per article.
    class NewsSentimentAnalyzer
      include Dry::Monads[:result]

      MAX_BATCH = 10

      SYSTEM_PROMPT = <<~PROMPT.freeze
        You are a financial news sentiment analyst.
        Classify each article as bullish, bearish, or neutral with a confidence score 0-100.
        Respond ONLY with valid JSON: {"articles": [{"title": "...", "sentiment": "bullish|bearish|neutral", "score": 75}]}
      PROMPT

      def self.analyze(articles:, gateway: nil)
        new(gateway: gateway).analyze(articles: articles)
      end

      def initialize(gateway: nil)
        @gateway = gateway || Gateways::LlmGateway.new
      end

      def analyze(articles:)
        return Success([]) if articles.empty?

        batch = articles.first(MAX_BATCH)
        prompt = build_prompt(batch)

        result = @gateway.complete(prompt: prompt, system_prompt: SYSTEM_PROMPT, max_tokens: 1000)
        return result if result.failure?

        parse_and_validate(result.value![:content])
      end

      private

      def build_prompt(articles)
        lines = articles.map.with_index(1) do |article, i|
          title = article.respond_to?(:title) ? article.title : article[:title]
          summary = article.respond_to?(:summary) ? article.summary : article[:summary]
          "#{i}. #{title} — #{summary}"
        end

        "Analyze sentiment for these articles:\n#{lines.join("\n")}"
      end

      def parse_and_validate(content)
        parsed = JSON.parse(content).deep_symbolize_keys

        # Clamp scores before validation
        parsed[:articles]&.each { |a| a[:score] = a[:score].to_i.clamp(0, 100) if a[:score] }

        contract = Contracts::SentimentResponseContract.new
        validation = contract.call(parsed)

        if validation.success?
          Success(parsed[:articles].map do |a|
            { title: a[:title], sentiment: a[:sentiment], score: a[:score] }
          end)
        else
          Failure([ :validation_error, validation.errors.to_h ])
        end
      rescue JSON::ParserError
        Failure([ :parse_error, "Invalid JSON response from LLM" ])
      end
    end
  end
end
