module Trading
  module UseCases
    class AssembleDashboard < ApplicationUseCase
      def call(user:)
        portfolio = user.portfolio
        currency = user.preferred_currency
        summary = portfolio ? Domain::PortfolioSummary.new(portfolio, currency: currency) : nil

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

        indices = MarketIndex.major.includes(:market_index_histories)

        sentiment = MarketData::Domain::MarketSentiment.for_user(user)

        fear_greed = {
          crypto: FearGreedReading.latest_crypto,
          stocks: FearGreedReading.latest_stocks,
          crypto_history: FearGreedReading.crypto.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value),
          stocks_history: FearGreedReading.stocks.recent.reorder(fetched_at: :asc).pluck(:fetched_at, :value)
        }

        weekly_insight = compute_weekly_insight(portfolio, currency)

        Success({
          summary: summary,
          watchlist_items: watchlist_items,
          news: news,
          trending: trending,
          indices: indices,
          sentiment: sentiment,
          fear_greed: fear_greed,
          weekly_insight: weekly_insight,
          currency: currency
        })
      end

      private

      def compute_weekly_insight(portfolio, currency)
        return { has_data: false } unless portfolio

        snapshots = portfolio.snapshots.where(date: 7.days.ago.to_date..Date.current).order(:date)
        # WeeklyInsightCalculator computes weekly_change as a percentage of
        # total_value — homogeneous currency is required for the percent
        # to be meaningful when snapshots straddle a preferred_currency
        # change. Pre-convert to the user's current currency here, routing
        # through Portfolio#convert so its FX cache amortizes the lookups.
        normalized = snapshots.map do |s|
          value = portfolio.convert(s.total_value, from: s.currency, to: currency)
          NormalizedSnapshot.new(date: s.date, total_value: value)
        end
        positions = portfolio.open_positions.includes(:asset)
        Domain::WeeklyInsightCalculator.calculate(snapshots: normalized, positions: positions)
      end

      NormalizedSnapshot = Data.define(:date, :total_value)
    end
  end
end
