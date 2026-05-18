class RemoveDefaultFromPortfolioSnapshotsCurrency < ActiveRecord::Migration[8.1]
  def up
    change_column_default :portfolio_snapshots, :currency, from: "USD", to: nil
  end

  def down
    change_column_default :portfolio_snapshots, :currency, from: nil, to: "USD"
  end
end
