require "csv"

module Administration
  module Logs
    class ExportCsv < ApplicationUseCase
      def call(admin:, params: {})
        logs = yield fetch_logs(params)
        csv  = yield generate(logs)
        _    = yield publish(Administration::CsvExported.new(user_id: admin.id, export_type: "system_logs"))

        Success(csv)
      end

      private

      def fetch_logs(params)
        scope = SystemLog.recent
        scope = scope.where(severity: params[:severity]) if params[:severity].present?
        scope = scope.by_module(params[:module_name])
        scope = scope.where("task_name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

        Success(scope)
      end

      def generate(logs)
        csv = CSV.generate(headers: true) do |csv|
          csv << %w[ID Severity Task Module Duration Timestamp Error]
          logs.find_each do |log|
            csv << [
              log.log_uid,
              log.severity,
              log.task_name,
              log.module_name,
              log.duration_seconds,
              log.created_at.iso8601,
              log.error_message
            ]
          end
        end
        Success(csv)
      end
    end
  end
end
