module Administration
  module UseCases
    module Integrations
      class ConnectProvider < ApplicationUseCase
        def call(admin:, params:)
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
            connection_status: :disconnected
          )
          return Failure([ :validation, integration.errors.to_hash ]) unless integration.save

          if attrs[:api_key_encrypted].present?
            integration.api_key_pools.create!(
              name: "Default",
              api_key_encrypted: attrs[:api_key_encrypted],
              is_default: true,
              enabled: true
            )
          end

          Success(integration)
        end
      end
    end
  end
end
