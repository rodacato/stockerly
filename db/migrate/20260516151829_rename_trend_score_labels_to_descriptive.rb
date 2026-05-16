class RenameTrendScoreLabelsToDescriptive < ActiveRecord::Migration[8.1]
  # Reorders the integer values backing TrendScore.label so they are monotonic
  # by magnitude, then renames the keys (rename happens at the Ruby layer in
  # app/models/trend_score.rb; this migration only shifts the integer values).
  #
  # Old mapping (creation-order):
  #   0=weak, 1=moderate, 2=strong, 3=parabolic, 4=sideways, 5=weakening
  #
  # New mapping (magnitude-ordered):
  #   0=low_score, 1=low_moderate, 2=neutral, 3=moderate, 4=high_score, 5=peak
  #
  # Row-level translation:
  #   weak (0) → low_score (0)        no change
  #   weakening (5) → low_moderate (1)
  #   sideways (4) → neutral (2)
  #   moderate (1) → moderate (3)
  #   strong (2) → high_score (4)
  #   parabolic (3) → peak (5)
  def up
    execute <<~SQL.squish
      UPDATE trend_scores SET label = CASE label
        WHEN 0 THEN 0
        WHEN 1 THEN 3
        WHEN 2 THEN 4
        WHEN 3 THEN 5
        WHEN 4 THEN 2
        WHEN 5 THEN 1
        ELSE label
      END
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE trend_scores SET label = CASE label
        WHEN 0 THEN 0
        WHEN 1 THEN 5
        WHEN 2 THEN 4
        WHEN 3 THEN 1
        WHEN 4 THEN 2
        WHEN 5 THEN 3
        ELSE label
      END
    SQL
  end
end
