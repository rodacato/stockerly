module Admin
  class ErrorsController < BaseController
    before_action :require_developer_mode

    def index
      data = Administration::UseCases::Errors::ListErrors.call(params: filter_params, request: request)

      @pagy = data[:pagy]
      @error_events = data[:errors]
    end

    def show
      @error_event = ErrorEvent.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_errors_path, alert: t(".no_encontrado")
    end

    def destroy
      ErrorEvent.find(params.expect(:id)).destroy!
      redirect_to admin_errors_path, notice: t(".eliminado")
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_errors_path, alert: t("admin.errors.show.no_encontrado")
    end

    private

    def filter_params
      params.permit(:source, :search, :page).to_h.symbolize_keys
    end

    def require_developer_mode
      return if SiteConfig.developer_mode?

      redirect_to admin_settings_path, alert: t("admin.errors.desactivado")
    end
  end
end
