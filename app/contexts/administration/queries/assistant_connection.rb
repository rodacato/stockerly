module Administration
  module Queries
    # The assistant's connection, as plain data. Administration owns the row
    # (it is an Integration); the assistant reads it here and never the model
    # (ADR-031 §4).
    class AssistantConnection
      PROVIDER_NAME = "Asistente".freeze
      PROVIDER_TYPE = "Assistant".freeze
      DEFAULT_BASE_URL = "https://api.anthropic.com".freeze
      DEFAULT_MODEL = "claude-haiku-5-5".freeze

      def self.call
        row = Integration.find_by(provider_name: PROVIDER_NAME)
        return nil unless row

        { base_url: row.setting("base_url"), model: row.setting("model"), api_key: row.active_api_key,
          masked_api_key: row.masked_api_key, status: row.connection_status.to_sym,
          failure_tag: row.last_failure_tag, checked_at: row.last_sync_at }
      end
    end
  end
end
