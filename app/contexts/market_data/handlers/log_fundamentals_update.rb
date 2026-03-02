module MarketData
  class LogFundamentalsUpdate
    def self.call(event)
      asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
      symbol   = event.is_a?(Hash) ? event[:symbol] : event.symbol
      source   = event.is_a?(Hash) ? event[:source] : event.source

      SystemLog.create!(
        task_name: "Fundamentals Update: #{symbol}",
        module_name: "sync",
        severity: :success,
        duration_seconds: 0,
        error_message: "Source: #{source}"
      )
    end
  end
end
