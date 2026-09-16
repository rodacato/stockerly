class WelcomeController < AuthenticatedController
  # The wizard's layout, not the app's: the reader is not onboarded until they
  # leave this screen, so every app link would bounce them back to step one.
  layout "onboarding"

  DOORS = { "portfolio" => :portfolio_path, "assets" => :assets_path, "alerts" => :alerts_path }.freeze

  def show
    redirect_to dashboard_path if current_user.onboarded?
  end

  # The last step of the wizard, and the only writer of onboarded_at: the flow
  # is done when the person leaves this screen, not when the sync starts.
  def complete
    Identity::UseCases::CompleteOnboarding.call(user: current_user)
    redirect_to send(DOORS.fetch(params[:destino], :dashboard_path))
  end
end
