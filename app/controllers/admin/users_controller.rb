module Admin
  class UsersController < BaseController
    include Pagy::Backend

    def index
      scope = User.all
      scope = scope.where("full_name ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
      scope = scope.order(created_at: :desc)

      @pagy, @users = pagy(scope, limit: 20, page: params[:page] || 1)
    end

    def suspend
      result = Admin::Users::SuspendUser.call(user_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_users_path, notice: "User suspended."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end
  end
end
