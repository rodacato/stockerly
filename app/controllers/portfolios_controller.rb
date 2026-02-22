class PortfoliosController < AuthenticatedController
  def show
    result = Portfolios::LoadOverview.call(user: current_user, tab: params[:tab] || "open")

    if result.success?
      data = result.value!
      @portfolio  = data[:portfolio]
      @positions  = data[:positions]
      @summary    = data[:summary]
      @allocation = data[:allocation]
      @tab        = data[:tab]
    else
      redirect_to dashboard_path, alert: "Portfolio not found."
    end
  end
end
