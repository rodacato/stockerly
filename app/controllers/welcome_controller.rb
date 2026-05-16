class WelcomeController < AuthenticatedController
  def show
    redirect_to dashboard_path if current_user.onboarded?
  end

  def complete
    Identity::UseCases::CompleteOnboarding.call(user: current_user)
    redirect_to dashboard_path
  end
end
