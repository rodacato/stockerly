class AllowNullAssetSymbolOnAlertRules < ActiveRecord::Migration[8.1]
  def change
    # Marketwide alert conditions (bmv_holiday, cete_auction) don't bind to a
    # ticker; their asset_symbol stays nil. Model-level presence validation
    # still enforces the requirement for asset-bound conditions.
    change_column_null :alert_rules, :asset_symbol, true
  end
end
