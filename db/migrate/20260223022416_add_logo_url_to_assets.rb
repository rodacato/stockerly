class AddLogoUrlToAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :logo_url, :string
  end
end
