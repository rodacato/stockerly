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
      csv = Administration::UseCases::Logs::ExportCsv.call(admin: current_user, params: filter_params).value!

      send_data csv, filename: "system_logs_#{Date.current}.csv", type: "text/csv"
    end

    private

    def filter_params
      params.permit(:severity, :module_name, :range, :search, :page).to_h.symbolize_keys
    end
  end
end
