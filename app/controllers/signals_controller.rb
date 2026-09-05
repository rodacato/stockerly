class SignalsController < AuthenticatedController
  def index
    @signals = Trading::UseCases::LoadSignals.call(user: current_user)
    @window_days = Trading::UseCases::LoadSignals::WINDOW_DAYS
  end
end
