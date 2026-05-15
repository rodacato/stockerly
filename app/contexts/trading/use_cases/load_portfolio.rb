module Trading
  module UseCases
    class LoadPortfolio < ApplicationUseCase
      def call(user:, tab: "open")
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        currency = user.preferred_currency
        summary = Domain::PortfolioSummary.new(portfolio, currency: currency)

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

        allocation = portfolio.allocation_by_sector(currency: currency)
        allocation_by_type = portfolio.allocation_by_asset_type(currency: currency)
        returns_calculator = Domain::PeriodReturnsCalculator.new(portfolio, currency: currency)

        Success({
          portfolio: portfolio,
          positions: positions,
          summary: summary,
          allocation: allocation,
          tab: tab,
          period_returns: returns_calculator.calculate,
          chart_data: returns_calculator.chart_data(period: "1M"),
          upcoming_dividends: tab == "dividends" ? Domain::UpcomingDividendsPresenter.new(portfolio).upcoming : [],
          allocation_by_type: allocation_by_type,
          currency: currency
        })
      end
    end
  end
end
