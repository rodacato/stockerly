class CreateSiteConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :site_configs do |t|
      t.string :key, null: false
      t.string :value, null: false, default: ""
      t.timestamps
    end

    add_index :site_configs, :key, unique: true
  end
end
