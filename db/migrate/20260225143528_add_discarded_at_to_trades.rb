class AddDiscardedAtToTrades < ActiveRecord::Migration[8.1]
  def change
    add_column :trades, :discarded_at, :datetime
    add_index :trades, :discarded_at
  end
end
