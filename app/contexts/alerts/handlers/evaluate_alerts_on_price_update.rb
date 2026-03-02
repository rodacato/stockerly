module Alerts
  class EvaluateAlertsOnPriceUpdate
    def self.async? = true

    def self.call(event)
      asset_id  = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
      new_price = event.is_a?(Hash) ? event[:new_price] : event.new_price
      old_price = event.is_a?(Hash) ? event[:old_price] : event.old_price

      Alerts::EvaluateRules.new.call(asset_id: asset_id, new_price: new_price, old_price: old_price)
    end
  end
end
