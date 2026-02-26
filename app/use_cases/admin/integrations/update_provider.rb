module Admin
  module Integrations
    class UpdateProvider < ApplicationUseCase
      def call(admin:, params:)
        attrs       = yield validate(Admin::Integrations::UpdateContract, params)
        integration = yield find(attrs[:id])
        changes     = yield update(integration, attrs)
        _           = yield publish(IntegrationUpdated.new(
          integration_id: integration.id,
          provider_name: integration.provider_name,
          changes: changes
        ))

        Success(integration)
      end

      private

      def find(id)
        integration = Integration.find_by(id: id)
        integration ? Success(integration) : Failure([:not_found, "Integration not found"])
      end

      def update(integration, attrs)
        update_attrs = attrs.except(:id).compact
        return Success({}) if update_attrs.empty?

        changes = update_attrs.each_with_object({}) do |(key, value), hash|
          old_value = integration.send(key)
          hash[key.to_s] = { from: old_value, to: value } if old_value != value
        end

        integration.update!(update_attrs)
        Success(changes)
      end
    end
  end
end
