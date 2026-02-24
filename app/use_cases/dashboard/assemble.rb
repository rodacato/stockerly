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

      fear_greed = {
        crypto: FearGreedReading.latest_crypto,
        stocks: FearGreedReading.latest_stocks,
        crypto_history: FearGreedReading.crypto.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value),
        stocks_history: FearGreedReading.stocks.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value)
      }

      Success({
        summary: summary,
        watchlist_items: watchlist_items,
        news: news,
        trending: trending,
        indices: indices,
        sentiment: sentiment,
        fear_greed: fear_greed
      })
    end
  end
end
