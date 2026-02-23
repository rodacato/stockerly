# Tests connectivity for an integration and updates its connection status.
# Used by Admin::Integrations::RefreshSync.
class SyncIntegrationJob < ApplicationJob
  queue_as :default

  def perform(integration_id)
    integration = Integration.find_by(id: integration_id)
    return unless integration

    integration.update!(connection_status: :syncing)

    result = test_connectivity(integration)

    if result.success?
      integration.update!(connection_status: :connected, last_sync_at: Time.current)
      log_result(integration, :success)
    else
      integration.update!(connection_status: :disconnected)
      log_result(integration, :error, result.failure[1])
    end
  end

  private

  def test_connectivity(integration)
    gateway = gateway_for(integration)
    return Dry::Monads::Failure([:not_found, "No gateway for #{integration.provider_name}"]) unless gateway

    # Simple connectivity test: fetch a known symbol
    case integration.provider_name
    when "Polygon.io"    then gateway.fetch_price("AAPL")
    when "CoinGecko"     then gateway.fetch_price("BTC")
    when "Yahoo Finance" then gateway.fetch_price("GENIUSSACV.MX")
    else
      Dry::Monads::Success(:ok)
    end
  end

  def gateway_for(integration)
    case integration.provider_name
    when "Polygon.io"    then PolygonGateway.new
    when "CoinGecko"     then CoingeckoGateway.new
    when "Yahoo Finance" then YahooFinanceGateway.new
    else nil
    end
  end

  def log_result(integration, severity, message = nil)
    SystemLog.create!(
      task_name: "Integration Sync: #{integration.provider_name}",
      module_name: "sync",
      severity: severity,
      error_message: message
    )
  end
end
