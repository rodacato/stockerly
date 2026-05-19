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

        # ADR-002: cross-context reads go through MarketData::Queries::* and
        # the explicitly-marked Domain read API (MarketSentiment.for_user).
        # No direct AR model access from inside Trading.
        news      = MarketData::Queries::RecentNews.call
        trending  = MarketData::Queries::TrendingAssets.call(limit: 5)
        indices   = MarketData::Queries::MajorIndices.call
        sentiment = MarketData::Domain::MarketSentiment.for_user(user)
        fear_greed = MarketData::Queries::CurrentFearGreed.call

        weekly_insight = compute_weekly_insight(portfolio, currency)
        upcoming_maturities = portfolio ? load_upcoming_maturities(portfolio) : []
        cetes_summary = portfolio ? compute_cetes_summary(upcoming_maturities, portfolio, currency) : nil

        Success({
          summary: summary,
          watchlist_items: watchlist_items,
          news: news,
          trending: trending,
          indices: indices,
          sentiment: sentiment,
          fear_greed: fear_greed,
          weekly_insight: weekly_insight,
          upcoming_maturities: upcoming_maturities,
          cetes_summary: cetes_summary,
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

      UPCOMING_MATURITY_WINDOW_DAYS = 30

      # Fixed-income positions whose lot-level maturity falls inside the
      # next 30 days, ordered by soonest first. Used by the dashboard
      # "Upcoming events" surface (#29 JTBD #3). The 30-day window is a
      # superset of the alert thresholds (7/3/1) so the user sees what's
      # coming weeks before an alert fires.
      def load_upcoming_maturities(portfolio)
        portfolio.positions
                 .where(status: :open)
                 .where(maturity_date: Date.current..(Date.current + UPCOMING_MATURITY_WINDOW_DAYS.days))
                 .order(:maturity_date)
                 .includes(:asset)
      end

      # Aggregate of fixed-income positions inside the upcoming-maturities
      # window: count, total face value in the user's preferred currency,
      # and days-to-soonest. Used by the dashboard CETES KPI card so the
      # MX investor sees liquidity-event exposure at a glance.
      #
      # Skips positions whose FX rate is missing (rather than failing the
      # whole dashboard) — the count reflects only convertible positions.
      def compute_cetes_summary(maturities, portfolio, currency)
        today = Date.current
        count = 0
        total = 0
        soonest = nil

        maturities.each do |p|
          next unless p.asset.asset_type_fixed_income?

          value =
            begin
              portfolio.convert(p.market_value, from: p.asset.currency, to: currency)
            rescue RuntimeError
              next
            end

          count += 1
          total += value
          days = (p.maturity_date - today).to_i
          soonest = days if soonest.nil? || days < soonest
        end

        { count: count, total_value: total, soonest_days: soonest }
      end
    end
  end
end
