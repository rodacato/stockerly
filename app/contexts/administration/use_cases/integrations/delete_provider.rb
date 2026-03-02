module Administration
  module Integrations
    class DeleteProvider < ApplicationUseCase
      def call(admin:, params:)
        attrs       = yield validate(Administration::Integrations::DeleteContract, params)
        integration = yield find(attrs[:id])
        provider    = integration.provider_name
        _           = yield destroy(integration)
        _           = yield publish(Administration::IntegrationDeleted.new(
          integration_id: attrs[:id],
          provider_name: provider
        ))

        Success(:deleted)
      end

      private

      def find(id)
        integration = Integration.find_by(id: id)
        integration ? Success(integration) : Failure([:not_found, "Integration not found"])
      end

      def destroy(integration)
        integration.destroy!
        Success(:destroyed)
      end
    end
  end
end
