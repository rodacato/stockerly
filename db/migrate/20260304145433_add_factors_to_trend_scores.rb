class AddFactorsToTrendScores < ActiveRecord::Migration[8.1]
  def change
    add_column :trend_scores, :factors, :jsonb, default: {}
  end
end
