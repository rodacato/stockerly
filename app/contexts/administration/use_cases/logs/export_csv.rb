require "csv"

module Administration
  module UseCases
    module Logs
      class ExportCsv < ApplicationUseCase
        def call(admin:, params: {})
          logs = yield fetch_logs(params)
          csv  = yield generate(logs)
          _    = yield publish(Administration::Events::CsvExported.new(user_id: admin.id, export_type: "system_logs"))

          Success(csv)
        end

        private

        def fetch_logs(params)
          Success(ListLogs.filtered(params))
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
end
