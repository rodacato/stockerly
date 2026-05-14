class RemoveCurrencyFromPositions < ActiveRecord::Migration[8.1]
  # Position's currency is now derived from `Asset.currency` (the source of truth
  # established in #41). The column on `positions` was a duplicate that could drift,
  # and the only callers (USA-centric scopes `domestic` / `international`) are
  # eliminated in #43. Reversible if needed via `down` below.

  # Local model classes — decouples migration from app code so renames or
  # association changes in future commits don't break this migration.
  class MigrationPosition < ActiveRecord::Base
    self.table_name = "positions"
    belongs_to :asset, class_name: "RemoveCurrencyFromPositions::MigrationAsset"
  end

  class MigrationAsset < ActiveRecord::Base
    self.table_name = "assets"
  end

  def up
    remove_column :positions, :currency
  end

  def down
    add_column :positions, :currency, :string, default: "USD", null: false
    MigrationPosition.reset_column_information
    MigrationPosition.includes(:asset).find_each do |p|
      p.update_column(:currency, p.asset&.currency || "USD")
    end
  end
end
