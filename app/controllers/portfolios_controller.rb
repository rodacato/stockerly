class PortfoliosController < AuthenticatedController
  def show
    data = Trading::UseCases::AssembleConsolidado.call(user: current_user, period: params[:period])

    @period         = data[:period]
    @from           = data[:from]
    @currency       = data[:currency]
    @summary        = data[:summary]
    @fx_unavailable = data[:fx_unavailable]
    @series         = data[:series]
    @twr            = data[:twr]
    @vs_cetes       = data[:vs_cetes]
    @vs_hold        = data[:vs_hold]
    @allocation     = data[:allocation]
  end
end
