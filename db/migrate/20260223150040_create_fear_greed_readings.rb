class CreateFearGreedReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :fear_greed_readings do |t|
      t.string   :index_type,     null: false
      t.integer  :value,          null: false
      t.string   :classification, null: false
      t.string   :source,         null: false
      t.jsonb    :component_data, default: {}
      t.datetime :fetched_at,     null: false
      t.timestamps
    end

    add_index :fear_greed_readings, [:index_type, :fetched_at]
  end
end
