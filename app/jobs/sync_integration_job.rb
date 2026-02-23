# Tests connectivity for an integration and updates its connection status.
# Used by Admin::Integrations::RefreshSync.
class SyncIntegrationJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform(integration_id)
    integration = Integration.find_by(id: integration_id)
    return unless integration

    integration.update!(connection_status: :syncing)

    result = test_connectivity(integration)

    if result.success?
      integration.update!(connection_status: :connected, last_sync_at: Time.current)
      log_sync_success("Integration Sync: #{integration.provider_name}")
    else
      integration.update!(connection_status: :disconnected)
      log_sync_failure("Integration Sync: #{integration.provider_name}", result.failure[1])
    end
  end

  private

  def test_connectivity(integration)
    source = DataSourceRegistry.for_integration(integration.provider_name)

    unless source
      return Dry::Monads::Failure([:not_found, "No gateway for #{integration.provider_name}"])
    end

    gateway = source.gateway_class.constantize.new
    test_symbol = source.test_symbol

    return Dry::Monads::Success(:ok) unless test_symbol

    gateway.fetch_price(test_symbol)
  end
end
