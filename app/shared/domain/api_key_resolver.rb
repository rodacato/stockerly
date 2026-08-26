# Resolves the single API key a provider is configured with.
# Replaces KeyRotation: ADR-015 retired multi-key pools, so there is one key
# per provider and nothing to rotate. Returns nil when the provider is unknown
# or has no key configured.
class ApiKeyResolver
  def self.for(provider_name)
    Integration.find_by(provider_name: provider_name)&.active_api_key
  end
end
