class AddProviderSymbolsToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :provider_symbols, :jsonb, default: {}, null: false
  end
end
