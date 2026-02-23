class CreateAssetFundamentals < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_fundamentals do |t|
      t.references :asset, null: false, foreign_key: true
      t.string   :period_label, null: false
      t.jsonb    :metrics, null: false, default: {}
      t.string   :source
      t.datetime :calculated_at
      t.timestamps
    end

    add_index :asset_fundamentals, [ :asset_id, :period_label ], unique: true
  end
end
