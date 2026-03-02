# Domain service for API key rotation with least-used selection strategy.
# Gateways call KeyRotation.next_key_for("Polygon.io") to get the
# least-used API key from the pool. Falls back to the integration's
# primary key when no pool keys exist.
class KeyRotation
  def self.next_key_for(provider_name)
    integration = Integration.find_by(provider_name: provider_name)
    return nil unless integration

    pool_key = integration.api_key_pools.enabled.least_used.first

    if pool_key
      pool_key.increment!(:daily_calls)
      pool_key.api_key_encrypted
    else
      integration.api_key_encrypted
    end
  end
end
