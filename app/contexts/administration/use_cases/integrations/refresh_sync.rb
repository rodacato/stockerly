module Administration
  module UseCases
    module Integrations
      class RefreshSync < ApplicationUseCase
        def call(integration_id:)
          integration = Integration.find_by(id: integration_id)
          return Failure([ :not_found, "Integration not found" ]) unless integration
          return Failure([ :missing_api_key, "API key required but not configured" ]) if integration.requires_api_key? && !integration.api_key_configured?

          SyncIntegrationJob.perform_later(integration.id)
          Success(:sync_enqueued)
        end
      end
    end
  end
end
