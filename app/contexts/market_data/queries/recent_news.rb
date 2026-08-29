module MarketData
  module Queries
    # Public read API: the recent headlines for one asset. Matches
    # `related_ticker` against the symbol and every symbol the asset used to
    # carry, so a rename does not silently drop the articles filed under the
    # old one.
    #
    # WINDOW_DAYS is a bound, not a default. An article older than it is not
    # returned at all, because a three-week-old headline sitting beside today's
    # price implies a link that is not there.
    class RecentNews
      WINDOW_DAYS = 7
      LIMIT = 5

      def self.call(asset:)
        tickers = ([ asset.symbol ] + Array(asset.former_symbols)).compact_blank.map { |ticker| ticker.to_s.upcase }.uniq
        return NewsArticle.none if tickers.empty?

        NewsArticle
          .for_tickers(tickers)
          .published_after(WINDOW_DAYS.days.ago)
          .order(published_at: :desc)
          .limit(LIMIT)
      end
    end
  end
end
