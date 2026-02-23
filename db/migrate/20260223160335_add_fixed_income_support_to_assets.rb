class AddFixedIncomeSupportToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :yield_rate,    :decimal, precision: 8, scale: 4
    add_column :assets, :maturity_date, :date
    add_column :assets, :face_value,    :decimal, precision: 15, scale: 2
  end
end
