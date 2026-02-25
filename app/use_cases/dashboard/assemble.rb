module Dashboard
  class Assemble < ApplicationUseCase
    def call(user:)
      portfolio = user.portfolio
      summary = portfolio ? PortfolioSummary.new(portfolio) : nil

      watchlist_items = user.watchlist_items
                            .includes(asset: [ :trend_scores, :asset_price_histories ])
                            .order(created_at: :desc)
                            .limit(10)

      news = NewsArticle.recent

      trending = Asset.where(asset_type: :stock)
                      .where.not(current_price: nil)
                      .where.not(change_percent_24h: nil)
                      .includes(:trend_scores)
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

      weekly_insight = compute_weekly_insight(portfolio)

      Success({
        summary: summary,
        watchlist_items: watchlist_items,
        news: news,
        trending: trending,
        indices: indices,
        sentiment: sentiment,
        fear_greed: fear_greed,
        weekly_insight: weekly_insight
      })
    end

    private

    def compute_weekly_insight(portfolio)
      return { has_data: false } unless portfolio

      snapshots = portfolio.snapshots.where(date: 7.days.ago.to_date..Date.current).order(:date)
      positions = portfolio.open_positions.includes(:asset)
      WeeklyInsightCalculator.calculate(snapshots: snapshots, positions: positions)
    end
  end
end
