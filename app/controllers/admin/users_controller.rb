module Admin
  class UsersController < BaseController
    def index
      result = Admin::Users::ListUsers.call(params: filter_params)
      data = result.value!

      @pagy  = data[:pagy]
      @users = data[:users]
    end

    def suspend
      result = Admin::Users::SuspendUser.call(user_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_users_path, notice: "User suspended."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    private

    def filter_params
      params.permit(:search, :page).to_h.symbolize_keys
    end
  end
end
