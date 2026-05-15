module MarketData
  module Queries
    # Public read API: returns the most recent news articles, ordered by
    # publication date (latest first). Used by Trading (dashboard) and any
    # other consumer that needs the "what's new" feed.
    #
    # ADR-002: this is the supplier-side wrapper for cross-context news
    # reads. Trading must call this instead of `NewsArticle.recent` directly.
    class RecentNews
      def self.call
        NewsArticle.recent
      end
    end
  end
end
