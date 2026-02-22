class RegistrationsController < ApplicationController
  layout "public"

  before_action :redirect_if_logged_in, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    result = Identity::Register.call(params: registration_params.to_h)

    case result
    in Dry::Monads::Success(user)
      start_session(user)
      redirect_to dashboard_path, notice: "Welcome to Stockerly, #{user.full_name}!"
    in Dry::Monads::Failure[:validation, errors]
      @user = User.new(registration_params)
      errors.each { |field, msgs| msgs.each { |msg| @user.errors.add(field, msg) } }
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
