module MarketData
  class LogDividendsSync
    def self.call(event)
      asset_count = event.is_a?(Hash) ? event[:asset_count] : event.asset_count
      dividend_count = event.is_a?(Hash) ? event[:dividend_count] : event.dividend_count

      SystemLog.create!(
        task_name: "Dividends Sync",
        module_name: "sync",
        severity: :success,
        duration_seconds: 0,
        error_message: "#{dividend_count} dividends synced across #{asset_count} assets"
      )
    end
  end
end
