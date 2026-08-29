class CreateTechnicalReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :technical_readings do |t|
      t.references :asset, null: false, foreign_key: true, index: { unique: true }
      t.datetime :calculated_at, null: false
      t.jsonb :readings, null: false, default: {}

      t.timestamps
    end
  end
end
