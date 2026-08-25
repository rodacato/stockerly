class WelcomeController < AuthenticatedController
  def show
    redirect_to dashboard_path if current_user.onboarded?
  end

  # The last step of the wizard, and the only writer of onboarded_at: the flow
  # is done when the person leaves this screen, not when the sync starts.
  def complete
    Identity::UseCases::CompleteOnboarding.call(user: current_user)
    redirect_to dashboard_path
  end
end
