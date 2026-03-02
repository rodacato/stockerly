module Administration
  module Integrations
    class AddPoolKey < ApplicationUseCase
      def call(admin:, params:)
        attrs       = yield validate(Administration::Integrations::AddPoolKeyContract, params)
        integration = yield find_integration(attrs[:integration_id])
        pool_key    = yield persist(integration, attrs)
        _           = yield publish(Administration::PoolKeyAdded.new(
          integration_id: integration.id,
          pool_key_id: pool_key.id,
          key_name: pool_key.name
        ))

        Success(pool_key)
      end

      private

      def find_integration(id)
        integration = Integration.find_by(id: id)
        integration ? Success(integration) : Failure([ :not_found, "Integration not found" ])
      end

      def persist(integration, attrs)
        pool_key = integration.api_key_pools.build(
          name: attrs[:name],
          api_key_encrypted: attrs[:api_key_encrypted]
        )
        pool_key.save ? Success(pool_key) : Failure([ :validation, pool_key.errors.to_hash ])
      end
    end
  end
end
