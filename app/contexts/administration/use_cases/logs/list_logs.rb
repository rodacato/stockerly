module Administration
  module UseCases
    module Logs
      class ListLogs < ApplicationUseCase
        include Pagy::Method

        def call(params: {}, request: nil)
          scope = SystemLog.recent
          scope = scope.where(severity: params[:severity]) if params[:severity].present?
          scope = scope.by_module(params[:module_name])
          scope = scope.where("task_name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

          pagy, logs = pagy(:offset, scope,
            limit: 20,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          Success({ pagy: pagy, logs: logs })
        end
      end
    end
  end
end
