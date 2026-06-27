class AuthenticatedController < ApplicationController
  layout "app"

  # Controller#action pairs whose successful HTML hits become a UserActivity
  # row. Keeps page-view recording explicit so unrelated authenticated
  # endpoints (image uploads, json fetches, debug actions) stay off the log.
  TRACKED_PAGE_VIEWS = {
    "dashboard"     => %w[show],
    "market"        => %w[index show],
    "portfolios"    => %w[show],
    "alerts"        => %w[index],
    "earnings"      => %w[index],
    "notifications" => %w[index],
    "profiles"      => %w[show]
  }.freeze

  before_action :check_session_timeout
  before_action :require_authentication
  before_action :redirect_to_onboarding
  after_action  :record_page_view

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Inicia sesión para continuar."
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

  # Records one UserActivity per successful HTML page load on a tracked
  # controller#action. Skips Turbo Stream / Turbo Frame / JSON requests so
  # in-page section reloads do not double-count a single page visit.
  def record_page_view
    return unless current_user
    return unless response.successful?
    return unless request.format.html?
    return if params[:format].to_s == "turbo_stream"
    return if request.headers["Turbo-Frame"].present?

    allowed_actions = TRACKED_PAGE_VIEWS[controller_name]
    return unless allowed_actions&.include?(action_name)

    ActivityRecorder.call(
      user:   current_user,
      action: "page_view:#{controller_name}##{action_name}",
      params: { controller: controller_name, action: action_name }
    )
  end
end
