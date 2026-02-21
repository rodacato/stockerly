class AuthenticatedController < ApplicationController
  layout "app"

  before_action :require_authentication

  private

  def require_authentication
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end
end
