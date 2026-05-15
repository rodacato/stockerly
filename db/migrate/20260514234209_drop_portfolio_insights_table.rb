class DropPortfolioInsightsTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :portfolio_insights
  end

  def down
    create_table :portfolio_insights do |t|
      t.references :user, null: false, foreign_key: true
      t.text :summary, null: false
      t.jsonb :observations, default: []
      t.jsonb :risk_factors, default: []
      t.string :provider
      t.datetime :generated_at, null: false
      t.timestamps
      t.index [ :user_id, :generated_at ]
    end
  end
end
