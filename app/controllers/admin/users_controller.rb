module Admin
  class UsersController < BaseController
    def index
      result = Administration::UseCases::Users::ListUsers.call(params: filter_params, request: request)
      data = result.value!

      @pagy        = data[:pagy]
      @users       = data[:users]
      @total_count = data[:total_count]
      @admin_count = data[:admin_count]
    end

    def suspend
      result = Administration::UseCases::Users::SuspendUser.call(user_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_users_path, notice: "Usuario suspendido."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    def reactivate
      result = Administration::UseCases::Users::ReactivateUser.call(user_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_users_path, notice: "Usuario reactivado."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    def destroy
      result = Administration::UseCases::Users::DeleteUser.call(user_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_users_path, notice: "Usuario eliminado permanentemente."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    private

    def filter_params
      params.permit(:search, :role, :status, :page).to_h.symbolize_keys
    end
  end
end
