module MarketData
  module Domain
    # The Alpha Vantage free tier gives a fixed number of fundamentals calls a
    # day, and that budget is what decides which assets get synced (D9).
    #
    # It counts the calls RateLimiter actually made, not log lines. Counting
    # logs was wrong three ways: a statements sync spends three calls and logs
    # one, failures spend quota and were filtered out by severity, and the only
    # reason statements consumption was counted at all was a copy-pasted log
    # prefix. The free tier could be exhausted while the screen showed headroom.
    class FundamentalsBudget
      PROVIDER = "Alpha Vantage".freeze
      DAILY_LIMIT = 25

      def self.today
        integration = Integration.find_by(provider_name: PROVIDER)
        return new(used: 0) if integration.nil?

        new(used: calls_today(integration), limit: integration.daily_call_limit || DAILY_LIMIT)
      end

      # The counter resets lazily on the next call rather than at midnight, so
      # a stale reset stamp means yesterday's number is still sitting there.
      def self.calls_today(integration)
        return 0 if integration.calls_reset_at.nil? || integration.calls_reset_at < Time.current.beginning_of_day

        integration.daily_api_calls
      end

      attr_reader :used, :limit

      def initialize(used:, limit: DAILY_LIMIT)
        @used = used
        @limit = limit
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
