module Admin
  class BaseController < AuthenticatedController
    before_action :require_admin

    private

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: t("admin.no_autorizado")
      end
    end
  end
end
