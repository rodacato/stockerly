class AuthenticatedController < ApplicationController
  layout "app"

  before_action :check_session_timeout
  before_action :require_authentication
  before_action :redirect_to_onboarding

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: t("auth.flash.requiere_sesion")
    end
  end

  def redirect_to_onboarding
    return unless current_user
    return if is_a?(WelcomeController)
    return if is_a?(OnboardingController)
    return if current_user.onboarded?

    redirect_to onboarding_integrations_path
  end
end
