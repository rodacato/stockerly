class CreateSiteConfigChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :site_config_changes do |t|
      t.string :key, null: false
      t.string :old_value
      t.string :new_value
      t.references :admin, foreign_key: { to_table: :users }, null: false
      t.timestamps
    end

    add_index :site_config_changes, :created_at
    add_index :site_config_changes, :key
  end
end
