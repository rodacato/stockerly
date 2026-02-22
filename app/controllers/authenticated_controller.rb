class AuthenticatedController < ApplicationController
  layout "app"

  before_action :require_authentication
  before_action :load_navbar_notifications

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end

  def load_navbar_notifications
    return unless current_user

    @navbar_notifications = current_user.notifications.recent.limit(6)
    @navbar_unread_count  = current_user.notifications.unread.count
  end
end
