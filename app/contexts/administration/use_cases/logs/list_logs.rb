module Administration
  module Logs
    class ListLogs < ApplicationUseCase
      include Pagy::Backend

      def call(params: {})
        scope = SystemLog.recent
        scope = scope.where(severity: params[:severity]) if params[:severity].present?
        scope = scope.by_module(params[:module_name])
        scope = scope.where("task_name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

        pagy, logs = pagy(scope, limit: 20, page: params[:page] || 1)

        Success({ pagy: pagy, logs: logs })
      end
    end
  end
end
