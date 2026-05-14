class RemoveCurrencyFromPositions < ActiveRecord::Migration[8.1]
  # Position's currency is now derived from `Asset.currency` (the source of truth
  # established in #41). The column on `positions` was a duplicate that could drift,
  # and the only callers (USA-centric scopes `domestic` / `international`) are
  # eliminated in #43. Reversible if needed via `down` below.
  def up
    remove_column :positions, :currency
  end

  def down
    add_column :positions, :currency, :string, default: "USD", null: false
    Position.includes(:asset).find_each { |p| p.update_column(:currency, p.asset.currency) }
  end
end
