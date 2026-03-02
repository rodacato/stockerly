module Administration
  module Integrations
    class RefreshSync < ApplicationUseCase
      def call(integration_id:)
        integration = Integration.find_by(id: integration_id)
        return Failure([ :not_found, "Integration not found" ]) unless integration

        SyncIntegrationJob.perform_later(integration.id)
        Success(:sync_enqueued)
      end
    end
  end
end
