module Administration
  module Handlers
    # The assistant verified its connection; the row it lives in is ours.
    class RecordAssistantVerification
      def self.call(event)
        row = Integration.find_by(provider_name: Queries::AssistantConnection::PROVIDER_NAME)
        return unless row

        if event.status == "ok"
          row.update!(connection_status: :connected, last_sync_at: Time.current, last_failure_tag: nil)
        else
          row.update!(connection_status: :disconnected, last_failure_at: Time.current, last_failure_tag: event.status)
        end
      end
    end
  end
end
