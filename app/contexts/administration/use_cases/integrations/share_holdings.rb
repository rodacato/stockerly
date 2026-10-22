module Administration
  module UseCases
    module Integrations
      # Puede leer tus posiciones (ADR-031's 2026-10-22 amendment). Off until the
      # owner turns it on, stored beside the connection whose host would receive them.
      class ShareHoldings < SimpleUseCase
        def call(allowed:)
          row = Integration.find_by!(provider_name: Queries::AssistantConnection::PROVIDER_NAME)
          row.update!(settings: row.settings.to_h.merge("read_holdings" => allowed))
        end
      end
    end
  end
end
