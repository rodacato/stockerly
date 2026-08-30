class RemoveChangePercent24hFromAssets < ActiveRecord::Migration[8.1]
  def change
    remove_column :assets, :change_percent_24h, :decimal, precision: 8, scale: 4
  end
end
