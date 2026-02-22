module Dashboard
  class Assemble < ApplicationUseCase
    def call(user:)
      portfolio = user.portfolio
      summary = portfolio ? PortfolioSummary.new(portfolio) : nil

      watchlist_items = user.watchlist_items
                            .includes(asset: :trend_scores)
                            .order(created_at: :desc)
                            .limit(10)

      news = NewsArticle.recent

      trending = Asset.where(asset_type: :stock)
                      .where.not(current_price: nil)
                      .where.not(change_percent_24h: nil)
                      .order(Arel.sql("ABS(change_percent_24h) DESC"))
                      .limit(5)

      indices = MarketIndex.major

      sentiment = MarketSentiment.for_user(user)

      Success({
        summary: summary,
        watchlist_items: watchlist_items,
        news: news,
        trending: trending,
        indices: indices,
        sentiment: sentiment
      })
    end
  end
end
