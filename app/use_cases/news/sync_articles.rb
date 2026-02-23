module News
  class SyncArticles < ApplicationUseCase
    def call
      result = PolygonGateway.new.fetch_news(limit: 20)

      return result if result.failure?

      articles = result.value!
      created = upsert_articles(articles)

      publish(NewsSynced.new(count: created))

      Success(created)
    end

    private

    def upsert_articles(articles)
      created = 0

      articles.each do |data|
        next if data[:url].blank?
        next if NewsArticle.exists?(url: data[:url])

        NewsArticle.create!(
          title: data[:title],
          summary: data[:summary],
          source: data[:source],
          url: data[:url],
          image_url: data[:image_url],
          published_at: data[:published_at],
          related_ticker: data[:related_ticker]
        )
        created += 1
      rescue ActiveRecord::RecordInvalid
        next
      end

      created
    end
  end
end
