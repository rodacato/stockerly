class PortfoliosController < AuthenticatedController
  def show
    result = Trading::UseCases::LoadPortfolio.call(
      user: current_user,
      tab: params[:tab] || "open"
    )

    if result.success?
      data = result.value!
      @portfolio            = data[:portfolio]
      @positions            = data[:positions]
      @summary              = data[:summary]
      @allocation           = data[:allocation]
      @tab                  = data[:tab]
      @period_returns       = data[:period_returns]
      @chart_data           = data[:chart_data]
      @upcoming_dividends   = data[:upcoming_dividends]
      @allocation_by_type   = data[:allocation_by_type]
    else
      redirect_to dashboard_path, alert: "Portfolio not found."
    end
  end
end
