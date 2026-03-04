module MarketData
  module UseCases
    class GeneratePortfolioInsight < ApplicationUseCase
      def call(user:)
        portfolio = user.portfolio
        return Failure([ :no_portfolio, "User has no portfolio" ]) unless portfolio

        positions = portfolio.open_positions.includes(:asset)
        return Failure([ :no_positions, "Portfolio has no open positions" ]) if positions.empty?

        summary = build_summary(portfolio, positions)
        concentration = Trading::Domain::ConcentrationAnalyzer.analyze(portfolio: portfolio)
        anonymized = Domain::PortfolioDataAnonymizer.anonymize(
          portfolio: portfolio, summary: summary, concentration: concentration
        )

        result = Domain::InsightGenerator.generate(portfolio_data: anonymized)
        return result if result.failure?

        insight = PortfolioInsight.create!(
          user: user,
          summary: result.value![:summary],
          observations: result.value![:observations],
          risk_factors: result.value![:risk_factors],
          provider: result.value![:provider],
          generated_at: result.value![:generated_at]
        )

        Success(insight)
      end

      private

      def build_summary(portfolio, positions)
        snapshots = portfolio.snapshots.where(date: 7.days.ago.to_date..Date.current).order(:date)
        weekly_change = if snapshots.size >= 2
          first_val = snapshots.first.total_value
          last_val = snapshots.last.total_value
          first_val.positive? ? ((last_val - first_val) / first_val * 100).to_f : 0.0
        end

        sorted = positions.sort_by { |p| p.asset.change_percent_24h || 0 }
        top = sorted.last
        worst = sorted.first

        {
          weekly_change: weekly_change,
          top_performer: top ? { symbol: top.asset.symbol, change_percent: top.asset.change_percent_24h&.to_f } : nil,
          worst_performer: worst ? { symbol: worst.asset.symbol, change_percent: worst.asset.change_percent_24h&.to_f } : nil
        }
      end
    end
  end
end
