class CreateSplitAdjustments < ActiveRecord::Migration[8.1]
  def up
    create_table :split_adjustments do |t|
      t.references :asset, null: false, foreign_key: true
      t.date :ex_date, null: false
      t.integer :ratio_from, null: false
      t.integer :ratio_to, null: false
      t.timestamps
    end

    add_index :split_adjustments, [ :asset_id, :ex_date ], unique: true

    execute <<~SQL.squish
      INSERT INTO split_adjustments (asset_id, ex_date, ratio_from, ratio_to, created_at, updated_at)
      SELECT asset_id, ex_date, ratio_from, ratio_to, applied_at, applied_at
      FROM stock_splits WHERE applied_at IS NOT NULL
    SQL

    remove_column :stock_splits, :applied_at
  end

  def down
    add_column :stock_splits, :applied_at, :datetime

    execute <<~SQL.squish
      UPDATE stock_splits SET applied_at = a.created_at
      FROM split_adjustments a
      WHERE a.asset_id = stock_splits.asset_id AND a.ex_date = stock_splits.ex_date
    SQL

    drop_table :split_adjustments
  end
end
