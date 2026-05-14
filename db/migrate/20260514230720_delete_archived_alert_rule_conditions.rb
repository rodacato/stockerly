class DeleteArchivedAlertRuleConditions < ActiveRecord::Migration[8.1]
  def up
    # condition: 5 = sentiment_above, 6 = sentiment_below, 8 = concentration_risk
    # All three are archived as part of Sprint 3 (issue #32) — the use cases,
    # handlers, and UI surfaces are gone. Orphan rows would point to enum
    # values the model no longer defines.
    execute <<~SQL
      DELETE FROM alert_events
      WHERE alert_rule_id IN (
        SELECT id FROM alert_rules WHERE condition IN (5, 6, 8)
      );
    SQL
    execute "DELETE FROM alert_rules WHERE condition IN (5, 6, 8);"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Archived alert rules (sentiment_above, sentiment_below, concentration_risk) cannot be restored; the supporting use cases were removed in #32."
  end
end
