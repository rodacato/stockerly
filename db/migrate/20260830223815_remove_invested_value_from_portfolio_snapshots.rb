class RemoveInvestedValueFromPortfolioSnapshots < ActiveRecord::Migration[8.1]
  # Both writers filled it with market value — the same number as total_value —
  # and no production code ever read it. Cost basis lives on the position.
  def change
    remove_column :portfolio_snapshots, :invested_value, :decimal, precision: 15, scale: 2, null: false
  end
end
