class SessionsController < ApplicationController
  layout "public"

  rate_limit to: 5, within: 1.minute, only: :create

  before_action :redirect_if_logged_in, only: [:new, :create]

  def new; end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      if user.suspended?
        redirect_to login_path, alert: "Your account has been suspended."
        return
      end

      start_session(user)
      remember(user) if params[:remember] == "1"
      redirect_to dashboard_path, notice: "Welcome back, #{user.full_name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    forget(current_user) if current_user
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end
end
