class PortfoliosController < AuthenticatedController
  def show
    data = Trading::UseCases::AssembleConsolidado.call(user: current_user, period: params[:period], by: allocation_view)

    @period         = data[:period]
    @from           = data[:from]
    @to             = data[:to]
    @currency       = data[:currency]
    @summary        = data[:summary]
    @fx_unavailable = data[:fx_unavailable]
    @prices_unavailable = data[:prices_unavailable]
    @series         = data[:series]
    @twr            = data[:twr]
    @vs_cetes       = data[:vs_cetes]
    @vs_hold        = data[:vs_hold]
    @vs_index       = data[:vs_index]
    @allocation     = data[:allocation]
    @allocation_view = allocation_view
    @currency_exposure = data[:currency_exposure]
  end

  private

  def allocation_view = params[:por] == "sector" ? "sector" : "type"
end
