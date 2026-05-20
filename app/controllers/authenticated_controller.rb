class AuthenticatedController < ApplicationController
  layout "app"

  before_action :check_session_timeout
  before_action :require_authentication
  before_action :redirect_to_onboarding

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end

  def redirect_to_onboarding
    return unless current_user
    return if is_a?(WelcomeController)
    return if is_a?(Admin::OnboardingController)
    return if current_user.onboarded?

    if current_user.admin?
      redirect_to admin_onboarding_integrations_path
    else
      redirect_to welcome_path
    end
  end
end
