module MarketData
  module Handlers
    class AnalyzeNewsSentiment
      def self.async?
        true
      end

      def self.call(_event)
        articles = NewsArticle.unanalyzed.order(published_at: :desc).limit(10)
        return if articles.empty?

        result = Domain::NewsSentimentAnalyzer.analyze(articles: articles)
        return unless result.success?

        sentiments = result.value!
        articles.each do |article|
          match = sentiments.find { |s| s[:title] == article.title }
          next unless match

          article.update!(
            sentiment: match[:sentiment],
            sentiment_score: match[:score],
            sentiment_analyzed_at: Time.current
          )
        end
      end
    end
  end
end
