module Admin
  class LogsController < BaseController
    def index
      result = Administration::UseCases::Logs::ListLogs.call(params: filter_params, request: request)

      if result.success?
        data  = result.value!
        @pagy = data[:pagy]
        @logs = data[:logs]
      end
    end

    def export_csv
      result = Administration::UseCases::Logs::ExportCsv.call(admin: current_user, params: filter_params)

      if result.success?
        send_data result.value!, filename: "system_logs_#{Date.current}.csv", type: "text/csv"
      else
        redirect_to admin_logs_path, alert: "Export failed."
      end
    end

    private

    def filter_params
      params.permit(:severity, :module_name, :search, :page).to_h.symbolize_keys
    end
  end
end
