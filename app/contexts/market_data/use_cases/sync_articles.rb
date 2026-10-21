module MarketData
  module UseCases
    class SyncArticles < ApplicationUseCase
      TITLE_SIMILARITY_THRESHOLD = 0.65
      TRACKED_LIMIT = 30
      TRACKED_ARTICLES = 50

      def call
        result = GatewayChain.for_capability(:news).fetch_news(limit: 20)

        return result if result.failure?

        created = upsert_articles(result.value!) + sync_tracked

        publish(Events::NewsSynced.new(count: created))

        Success(created)
      end

    private

    # The general feed answers with whatever the market is talking about, which
    # rarely names what one person holds. One more call asks for the tracked
    # US symbols together (Alpaca takes a list; the Finnhub fallback takes one
    # symbol, so this is not routed through the chain). Its failure never fails
    # the general sync.
    def sync_tracked
      equities = Asset.syncing.where(asset_type: %i[stock etf])
      symbols = equities.where(country: [ nil, "" ]).or(equities.where.not(country: "MX")).limit(TRACKED_LIMIT).pluck(:symbol)
      return 0 if symbols.empty?

      result = Gateways::AlpacaGateway.new.fetch_news(ticker: symbols.join(","), limit: TRACKED_ARTICLES)
      result.success? ? upsert_articles(result.value!) : 0
    end

    def upsert_articles(articles)
      created = 0
      recent_titles = NewsArticle.where(published_at: 48.hours.ago..).pluck(:title)

      articles.each do |data|
        next if data[:url].blank?
        next if NewsArticle.exists?(url: data[:url])
        next if similar_title_exists?(data[:title], recent_titles)

        NewsArticle.create!(
          title: data[:title],
          summary: data[:summary],
          source: data[:source],
          url: data[:url],
          image_url: data[:image_url],
          published_at: data[:published_at],
          related_ticker: data[:related_ticker]
        )
        recent_titles << data[:title]
        created += 1
      rescue ActiveRecord::RecordInvalid
        next
      end

      created
    end

    def similar_title_exists?(new_title, existing_titles)
      return false if new_title.blank?

      normalized_new = normalize_title(new_title)
      existing_titles.any? do |existing|
        dice_coefficient(normalized_new, normalize_title(existing)) >= TITLE_SIMILARITY_THRESHOLD
      end
    end

    def normalize_title(title)
      title.downcase.gsub(/[^a-z0-9\s]/, "").gsub(/\s+/, " ").strip
    end

    def dice_coefficient(a, b)
      return 1.0 if a == b
      return 0.0 if a.length < 2 || b.length < 2

      bigrams_a = (0...(a.length - 1)).map { |i| a[i, 2] }.to_set
      bigrams_b = (0...(b.length - 1)).map { |i| b[i, 2] }.to_set

      intersection = (bigrams_a & bigrams_b).size
      (2.0 * intersection) / (bigrams_a.size + bigrams_b.size)
    end
    end
  end
end
