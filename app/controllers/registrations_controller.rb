class RegistrationsController < ApplicationController
  layout "public"

  before_action :redirect_if_logged_in, only: [:new, :create]

  def new
    @user = User.new
  end

  # TODO: Replace with Identity::Register.call(name:, email:, password:, password_confirmation:)
  #       -> Success(user) | Failure(:validation, errors)
  def create
    @user = User.new(registration_params)

    if @user.save
      EventBus.publish(UserRegistered.new(user_id: @user.id, email: @user.email))
      start_session(@user)
      redirect_to dashboard_path, notice: "Welcome to Stockerly, #{@user.full_name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.permit(:full_name, :email, :password, :password_confirmation)
  end

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end
end
