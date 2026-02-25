module Portfolios
  class LoadOverview < ApplicationUseCase
    def call(user:, tab: "open")
      portfolio = user.portfolio
      return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

      summary = PortfolioSummary.new(portfolio)

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
      returns_calculator = PeriodReturnsCalculator.new(portfolio)

      Success({
        portfolio: portfolio,
        positions: positions,
        summary: summary,
        allocation: allocation,
        tab: tab,
        period_returns: returns_calculator.calculate,
        chart_data: returns_calculator.chart_data(period: "1M")
      })
    end
  end
end
