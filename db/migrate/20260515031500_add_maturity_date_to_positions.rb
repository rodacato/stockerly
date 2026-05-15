class AddMaturityDateToPositions < ActiveRecord::Migration[8.1]
  # Lot-level maturity for fixed-income positions (#29 closes JTBD #3).
  # `Asset.maturity_date` is the abstract instrument's nominal maturity which
  # is meaningless for CETES (the symbol rolls — `SyncCetes` previously
  # overwrote it on every sync, masking each lot's actual expiry). The
  # per-position date is captured at purchase and frozen for the life of
  # the position.
  def change
    add_column :positions, :maturity_date, :date, null: true
    add_index :positions, :maturity_date, where: "maturity_date IS NOT NULL"
  end
end
