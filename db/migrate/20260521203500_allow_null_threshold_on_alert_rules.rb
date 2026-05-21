class AllowNullThresholdOnAlertRules < ActiveRecord::Migration[8.1]
  def change
    # Date-based conditions (dividend_ex_date, bmv_holiday, cete_auction) fire
    # on a calendar date, not a numeric threshold. Marketwide types in
    # particular have no meaningful threshold at all. Drop the DB-level NOT
    # NULL constraint; model-level validation enforces presence only for
    # asset/price-based conditions.
    change_column_null :alert_rules, :threshold_value, true
  end
end
