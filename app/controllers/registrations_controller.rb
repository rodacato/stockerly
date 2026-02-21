class RegistrationsController < ApplicationController
  layout "public"

  before_action :redirect_if_logged_in, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_session(@user)
      redirect_to root_path, notice: "Welcome to TrendStocker, #{@user.full_name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.permit(:full_name, :email, :password, :password_confirmation)
  end

  def redirect_if_logged_in
    redirect_to root_path if logged_in?
  end
end
