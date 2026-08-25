class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  before_action :redirect_to_setup
  before_action :check_maintenance_mode
  before_action :set_sentry_context

  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
    payload[:ip] = request.remote_ip
  end

  private

  def redirect_to_setup
    return if User.exists?
    return if is_a?(SetupController)
    return if controller_path == "rails/health" || controller_name == "health"

    redirect_to setup_path
  end

  def check_maintenance_mode
    return unless SiteConfig.maintenance_mode?
    return if current_user&.admin?
    return if is_a?(SetupController)
    return if is_a?(SessionsController)
    return if controller_path == "rails/health" || controller_name == "health"

    render "shared/maintenance", layout: "public", status: :service_unavailable
  end

  def set_sentry_context
    Sentry.set_user(id: current_user&.id, email: current_user&.email)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def start_session(user)
    reset_session
    session[:user_id] = user.id
    session[:session_started_at] = Time.current.to_i
    session[:last_activity_at] = Time.current.to_i
  end

  INACTIVITY_TIMEOUT = 14.days.to_i
  ABSOLUTE_TIMEOUT = 30.days.to_i

  def check_session_timeout
    return unless session[:user_id]

    now = Time.current.to_i

    if session[:session_started_at] && (now - session[:session_started_at]) > ABSOLUTE_TIMEOUT
      expire_session(t("auth.session.expirada"))
    elsif session[:last_activity_at] && (now - session[:last_activity_at]) > INACTIVITY_TIMEOUT
      expire_session(t("auth.session.inactividad"))
    else
      session[:last_activity_at] = now
    end
  end

  def expire_session(message)
    reset_session
    redirect_to login_path, alert: message
  end
end
