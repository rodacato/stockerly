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
      # D173: no green, amber or rose (gain, warning, loss), and no grey, which is "Sin conexión".
      VELITA_COLOURS = %w[indigo cielo violeta naranja cian].freeze

      def self.call
        row = Integration.find_by(provider_name: PROVIDER_NAME)
        return nil unless row

        model = row.setting("model")
        { base_url: row.setting("base_url"), model:, planner_model: row.setting("planner_model") || model,
          api_key: row.active_api_key, masked_api_key: row.masked_api_key, status: row.connection_status.to_sym,
          failure_tag: row.last_failure_tag, checked_at: row.last_sync_at,
          show_velita: row.setting("show_velita") == true, read_holdings: row.setting("read_holdings") == true,
          velita_colour: row.setting("velita_colour").presence_in(VELITA_COLOURS) || VELITA_COLOURS.first }
      end
    end
  end
end
