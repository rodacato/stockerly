module MarketData
  class LogMarketIndicesUpdate
    def self.call(event)
      count = event.is_a?(Hash) ? event[:count] : event.count

      SystemLog.create!(
        task_name: "Market Indices Sync",
        module_name: "sync",
        severity: :success,
        duration_seconds: 0,
        error_message: "#{count} indices updated"
      )
    end
  end
end
