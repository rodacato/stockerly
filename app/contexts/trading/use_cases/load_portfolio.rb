module Trading
  module UseCases
    class LoadPortfolio < ApplicationUseCase
      BENCHMARK_INDICES = %w[SPX NDX DJI].freeze
      BenchmarkPoint = Data.define(:date, :total_value, :invested_value)

      def call(user:, tab: "open", benchmark: nil)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        summary = Domain::PortfolioSummary.new(portfolio)

        positions = case tab
        when "closed"
                      portfolio.closed_positions.includes(:asset)
        when "dividends"
                      portfolio.dividend_payments.includes(dividend: :asset).recent
        when "trades"
                      portfolio.trades.recent.includes(:asset).limit(50)
        else
                      portfolio.open_positions.includes(:asset)
        end

        allocation = portfolio.allocation_by_sector
        allocation_by_type = portfolio.allocation_by_asset_type
        returns_calculator = Domain::PeriodReturnsCalculator.new(portfolio)

        risk_metrics = compute_risk_metrics(portfolio)

        result = {
          portfolio: portfolio,
          positions: positions,
          summary: summary,
          allocation: allocation,
          tab: tab,
          period_returns: returns_calculator.calculate,
          chart_data: returns_calculator.chart_data(period: "1M"),
          benchmark_data: nil,
          upcoming_dividends: tab == "dividends" ? Domain::UpcomingDividendsPresenter.new(portfolio).upcoming : [],
          risk_metrics: risk_metrics,
          allocation_by_type: allocation_by_type
        }

        if benchmark.present? && BENCHMARK_INDICES.include?(benchmark)
          result[:benchmark_data] = compute_benchmark(portfolio, benchmark)
        end

        Success(result)
      end

      private

      def compute_risk_metrics(portfolio)
        snapshots = portfolio.snapshots.order(:date)
        Domain::PortfolioRiskCalculator.new(snapshots: snapshots).calculate
      end

      def compute_benchmark(portfolio, benchmark_symbol)
        index = MarketIndex.find_by(symbol: benchmark_symbol)
        return nil unless index

        snapshots = portfolio.snapshots.order(:date)
        return nil if snapshots.size < 2

        start_date = snapshots.first.date
        end_date = snapshots.last.date

        index_histories = index.market_index_histories.for_period(start_date, end_date)
        return nil if index_histories.size < 2

        portfolio_twr = Domain::TimeWeightedReturn.new(snapshots: snapshots).calculate

        # Wrap index histories to match TWR's expected interface (total_value, invested_value)
        benchmark_snapshots = index_histories.map do |h|
          BenchmarkPoint.new(date: h.date, total_value: h.close_value, invested_value: h.close_value)
        end
        benchmark_twr = Domain::TimeWeightedReturn.new(snapshots: benchmark_snapshots).calculate

        {
          symbol: benchmark_symbol,
          name: index.name,
          portfolio_twr: portfolio_twr,
          benchmark_twr: benchmark_twr,
          benchmark_chart: index_histories.map { |h| { date: h.date, value: h.close_value.to_f } }
        }
      end
    end
  end
end
