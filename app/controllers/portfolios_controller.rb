class PortfoliosController < AuthenticatedController
  def show
    result = Portfolios::LoadOverview.call(
      user: current_user,
      tab: params[:tab] || "open",
      benchmark: params[:benchmark]
    )

    if result.success?
      data = result.value!
      @portfolio       = data[:portfolio]
      @positions       = data[:positions]
      @summary         = data[:summary]
      @allocation      = data[:allocation]
      @tab             = data[:tab]
      @period_returns  = data[:period_returns]
      @chart_data      = data[:chart_data]
      @benchmark_data       = data[:benchmark_data]
      @benchmark            = params[:benchmark]
      @upcoming_dividends   = data[:upcoming_dividends]
      @risk_metrics         = data[:risk_metrics]
      @allocation_by_type   = data[:allocation_by_type]
    else
      redirect_to dashboard_path, alert: "Portfolio not found."
    end
  end
end
