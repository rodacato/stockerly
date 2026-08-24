class DashboardController < AuthenticatedController
  def show
    data = Trading::UseCases::AssemblePanorama.call(user: current_user)

    @currency        = data[:currency]
    @summary         = data[:summary]
    @fx_unavailable  = data[:fx_unavailable]
    @sentiment_cards = data[:sentiment_cards]
    @movements       = data[:movements]
    @radar           = data[:radar]
  end
end
