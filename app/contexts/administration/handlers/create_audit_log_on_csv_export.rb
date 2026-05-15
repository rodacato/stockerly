module Administration
  module Handlers
    # Audit: admin exported a CSV. Data export is a security-relevant
    # action — even when the data is non-sensitive, the export is a
    # trail we want for compliance.
    class CreateAuditLogOnCsvExport
      def self.call(event)
        AuditLog.create!(
          user_id: event.user_id,
          action: "csv_exported",
          changes_data: { export_type: event.export_type }
        )
      end
    end
  end
end
