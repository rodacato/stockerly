class CreateAppOpens < ActiveRecord::Migration[8.1]
  def change
    create_table :app_opens do |t|
      t.date :day, null: false
      t.string :path, null: false
      t.integer :count, null: false, default: 0
      t.timestamps
    end

    add_index :app_opens, [ :day, :path ], unique: true
  end
end
