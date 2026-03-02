module Administration
  module Integrations
    class ConnectProvider < ApplicationUseCase
      def call(admin:, params:)
        attrs       = yield validate(Administration::Integrations::ConnectContract, params)
        integration = yield persist(attrs)
        _           = yield publish(Administration::IntegrationConnected.new(
          integration_id: integration.id,
          provider_name: integration.provider_name
        ))

        Success(integration)
      end

      private

      def persist(attrs)
        integration = Integration.new(
          provider_name: attrs[:provider_name],
          provider_type: attrs[:provider_type],
          api_key_encrypted: attrs[:api_key_encrypted],
          connection_status: :disconnected
        )
        integration.save ? Success(integration) : Failure([ :validation, integration.errors.to_hash ])
      end
    end
  end
end
