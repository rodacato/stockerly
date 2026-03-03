module MarketData
  module Handlers
    class LogEarningsSync
      def self.call(event)
        count = event.is_a?(Hash) ? event[:count] : event.count

        SystemLog.create!(
          task_name: "Earnings Sync",
          module_name: "sync",
          severity: :success,
          duration_seconds: 0,
          error_message: "#{count} earnings events synced"
        )
      end
    end
  end
end
