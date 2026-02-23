class AddCountryToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :country, :string, limit: 2
    add_index :assets, :country
    add_index :assets, [ :country, :asset_type ]
  end
end
