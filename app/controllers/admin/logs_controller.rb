module Admin
  class LogsController < BaseController
    include Pagy::Backend

    def index
      result = Admin::Logs::ListLogs.call(params: filter_params)

      if result.success?
        data  = result.value!
        @pagy = data[:pagy]
        @logs = data[:logs]
      end
    end

    private

    def filter_params
      params.permit(:severity, :module_name, :search, :page).to_h.symbolize_keys
    end
  end
end
