module Administration
  module UseCases
    module Integrations
      class UpdateProvider < ApplicationUseCase
        def call(admin:, params:)
          attrs       = yield validate(Administration::Contracts::Integrations::UpdateContract, params)
          integration = yield find(attrs[:id])
          changes     = yield update(integration, attrs)
          _           = yield publish(Administration::Events::IntegrationUpdated.new(
            integration_id: integration.id,
            provider_name: integration.provider_name,
            changes: changes
          ))

          Success(integration)
        end

        private

        def find(id)
          integration = Integration.find_by(id: id)
          integration ? Success(integration) : Failure([ :not_found, "Integration not found" ])
        end

        def update(integration, attrs)
          api_key_value = attrs[:api_key_encrypted]
          update_attrs = attrs.except(:id, :api_key_encrypted).compact

          if api_key_value.present?
            upsert_default_pool_key(integration, api_key_value)
            if integration.connection_status != "connected"
              update_attrs[:connection_status] = :connected
              update_attrs[:last_sync_at] = Time.current
            end
          end

          return Success({}) if update_attrs.empty? && api_key_value.blank?

          changes = update_attrs.each_with_object({}) do |(key, value), hash|
            old_value = integration.send(key)
            hash[key.to_s] = { from: old_value, to: value } if old_value != value
          end
          changes["api_key_encrypted"] = { from: "[FILTERED]", to: "[FILTERED]" } if api_key_value.present?

          integration.update!(update_attrs) if update_attrs.present?
          Success(changes)
        end

        def upsert_default_pool_key(integration, api_key_value)
          default_key = integration.api_key_pools.find_by(is_default: true)
          if default_key
            default_key.update!(api_key_encrypted: api_key_value)
          else
            integration.api_key_pools.create!(
              name: "Default",
              api_key_encrypted: api_key_value,
              is_default: true,
              enabled: true
            )
          end
        end
      end
    end
  end
end
