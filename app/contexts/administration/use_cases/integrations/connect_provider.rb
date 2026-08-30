module Administration
  module UseCases
    module Integrations
      class ConnectProvider < ApplicationUseCase
        def call(params:)
          attrs       = yield validate(Administration::Contracts::Integrations::ConnectContract, params)
          integration = yield persist(attrs)
          _           = yield publish(Administration::Events::IntegrationConnected.new(
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
            connection_status: :disconnected,
            api_key_encrypted: attrs[:api_key_encrypted].presence
          )
          return Failure([ :validation, integration.errors.to_hash ]) unless integration.save

          Success(integration)
        end
      end
    end
  end
end
