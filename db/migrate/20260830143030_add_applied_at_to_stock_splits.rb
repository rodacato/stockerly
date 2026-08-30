class AddAppliedAtToStockSplits < ActiveRecord::Migration[8.1]
  def up
    add_column :stock_splits, :applied_at, :datetime

    # Every existing row was adjusted when it was detected. Leaving them NULL
    # would invite the second application this column exists to prevent.
    execute "UPDATE stock_splits SET applied_at = updated_at"
  end

  def down
    remove_column :stock_splits, :applied_at
  end
end
