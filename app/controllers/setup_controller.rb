class SetupController < ApplicationController
  layout "public"

  before_action :require_no_users

  def new; end

  def create
    result = Identity::UseCases::CreateFirstAdmin.call(params: setup_params)

    if result.success?
      user = result.value!
      start_session(user)
      redirect_to admin_onboarding_integrations_path, notice: "Admin account created! Let's configure your instance."
    else
      case result.failure
      in [ :validation, errors ]
        @errors = errors
        render :new, status: :unprocessable_content
      in [ :setup_complete, _ ]
        redirect_to root_path, alert: "Setup already completed."
      end
    end
  end

  private

  def require_no_users
    redirect_to root_path if User.exists?
  end

  def setup_params
    params.permit(:full_name, :email, :password, :password_confirmation).to_h.symbolize_keys
  end
end
