module MarketData
  module Domain
    # The Alpha Vantage free tier gives 25 fundamentals calls a day, and that
    # budget is what decides which assets get synced (D9). It was private inside
    # SyncAllFundamentalsJob; Rastreados has to show it, so it lives here and the
    # job reads the same numbers the screen does.
    class FundamentalsBudget
      DAILY_LIMIT = 25

      def self.today
        used = SystemLog.where("task_name LIKE ?", "Fundamentals: %")
                        .where(severity: :success)
                        .where(created_at: Date.current.all_day)
                        .count

        new(used: used)
      end

      attr_reader :used, :limit

      def initialize(used:, limit: DAILY_LIMIT)
        @used = used
        @limit = limit
      end

      def remaining
        [ limit - used, 0 ].max
      end

      def exhausted?
        remaining.zero?
      end

      def used_percent
        return 0 if limit.zero?

        (used.to_f / limit * 100).clamp(0, 100).round
      end
    end
  end
end
