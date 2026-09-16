module MarketData
  module Domain
    # The daily quota of the provider that leads the fundamentals chain, which
    # is what decides which assets get synced (D9). It is that provider's whole
    # day — prices and indices spend it too — not a share set aside (D123).
    #
    # It counts the calls RateLimiter actually made, not log lines. Counting
    # logs was wrong three ways: a statements sync spends three calls and logs
    # one, failures spend quota and were filtered out by severity, and the only
    # reason statements consumption was counted at all was a copy-pasted log
    # prefix. The free tier could be exhausted while the screen showed headroom.
    class FundamentalsBudget
      def self.today
        provider = DataSourceRegistry.for_capability(:fundamentals).first&.integration_name
        integration = Integration.find_by(provider_name: provider)
        return new(used: 0, limit: nil, provider: provider) if integration.nil?

        new(used: calls_today(integration), limit: integration.daily_call_limit, provider: provider)
      end

      # The counter resets lazily on the next call rather than at midnight, so
      # a stale reset stamp means yesterday's number is still sitting there.
      def self.calls_today(integration)
        return 0 if integration.calls_reset_at.nil? || integration.calls_reset_at < Time.current.beginning_of_day

        integration.daily_api_calls
      end

      attr_reader :used, :limit, :provider

      # A nil limit is unlimited, as RateLimiter reads it.
      def initialize(used:, limit:, provider: nil)
        @used = used
        @limit = limit
        @provider = provider
      end

      def remaining
        return Float::INFINITY if limit.nil?

        [ limit - used, 0 ].max
      end

      def exhausted?
        remaining.zero?
      end

      def unlimited?
        limit.nil?
      end

      def used_percent
        return 0 if limit.nil? || limit.zero?

        (used.to_f / limit * 100).clamp(0, 100).round
      end
    end
  end
end
