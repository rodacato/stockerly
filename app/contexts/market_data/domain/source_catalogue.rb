module MarketData
  module Domain
    # What Integraciones has to answer per source: what it serves, in what
    # role, how much of its own quota is left, and whose problem a failure is.
    class SourceCatalogue
      # `sin cuota` is our own counter stopping us and it resumes tomorrow;
      # `bloqueada` is the provider refusing and no waiting fixes it.
      STATES = %i[connected no_key no_quota blocked].freeze

      # A provider's meter is its own: calls a minute, calls a day, or KiB a
      # month. One integer cannot render all three, so the unit travels along.
      Quota = Data.define(:used, :limit, :unit) do
        def known? = limit.present? && limit.positive?

        def ratio
          known? ? (used.to_f / limit).clamp(0.0, 1.0) : 0.0
        end

        def near_limit? = known? && ratio >= 0.7

        def exhausted? = known? && used >= limit
      end

      Entry = Data.define(
        :key, :provider, :name, :description, :capabilities,
        :role, :state, :quota, :last_sync_at, :requires_key, :maintainer_only
      ) do
        def working? = state == :connected
        def only_source? = role == :only
      end

      def self.all = new.all

      def self.for_capability(capability) = new.for_capability(capability)

      def all
        DataSourceRegistry.all
                          .group_by(&:integration_name)
                          .filter_map { |provider, sources| entry_for(provider, sources) }
                          .sort_by { |entry| [ entry.state == :connected ? 1 : 0, entry.provider ] }
      end

      # In the registry's own order, which is the order GatewayChain builds:
      # the screen cannot claim a priority the chain does not follow.
      def for_capability(capability)
        entries = DataSourceRegistry.for_capability(capability)
                                    .filter_map { |source| by_provider[source.integration_name] }
                                    .uniq
        { primary: entries.first, fallbacks: entries.drop(1) }
      end

      private

      def by_provider
        @by_provider ||= all.index_by(&:provider)
      end

      def integrations
        @integrations ||= Integration.all.index_by(&:provider_name)
      end

      def entry_for(provider, sources)
        integration = integrations[provider]
        return nil if integration.nil?

        info = MarketData::Domain::ProviderDirectory.for(provider)
        capabilities = sources.flat_map(&:capabilities).uniq

        Entry.new(
          key: sources.first.key,
          provider: provider,
          name: provider,
          description: info&.description,
          capabilities: capabilities,
          role: role_for(sources, provider),
          state: state_for(integration),
          quota: quota_for(integration, sources.first),
          last_sync_at: integration.last_sync_at,
          requires_key: integration.requires_api_key?,
          maintainer_only: sources.any?(&:maintainer_only)
        )
      end

      # Asked inside each source's own declared scope, because an unscoped
      # question answers wrong: CoinGecko is one of four for :prices overall
      # and the only one for crypto.
      def role_for(sources, provider)
        peers = sources.flat_map { |source| peers_for(source) }

        return :only    if peers.any?([ provider ])
        return :primary if peers.any? { |names| names.first == provider }

        :fallback
      end

      def peers_for(source)
        source.capabilities.map do |capability|
          DataSourceRegistry
            .for_capability(capability, market: source.markets&.first, asset_type: source.asset_types&.first)
            .map(&:integration_name).uniq
        end
      end

      def state_for(integration)
        return :no_key   if integration.requires_api_key? && !integration.api_key_configured?
        return :no_quota if integration.budget_exhausted? || integration.minute_budget_exhausted?
        return :blocked  if integration.disconnected? || refused?(integration)

        :connected
      end

      # Checked after quota on purpose: our own RateLimiter and a provider's
      # 429 both surface as :rate_limited, and the counters tell them apart.
      def refused?(integration)
        tag = integration.last_failure_tag
        return false if tag.blank?

        GatewayFailure.permanent?(tag) || tag == "rate_limited"
      end

      def quota_for(integration, source)
        gateway = source.gateway_class
        return gateway.quota(integration) if gateway.respond_to?(:quota)

        if integration.max_requests_per_minute.present?
          Quota.new(used: integration.minute_calls, limit: integration.max_requests_per_minute, unit: :calls_per_minute)
        else
          Quota.new(used: integration.daily_api_calls, limit: integration.daily_call_limit, unit: :calls_per_day)
        end
      end
    end
  end
end
