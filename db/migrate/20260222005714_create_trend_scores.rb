class CreateTrendScores < ActiveRecord::Migration[8.1]
  def change
    create_table :trend_scores do |t|
      t.references :asset,        null: false, foreign_key: true
      t.integer    :score,        null: false
      t.integer    :label,        null: false, default: 0
      t.integer    :direction,    null: false, default: 0
      t.datetime   :calculated_at, null: false

      t.timestamps
    end

    add_index :trend_scores, [ :asset_id, :calculated_at ]
    add_index :trend_scores, :score
  end
end
