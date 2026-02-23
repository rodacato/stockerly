class CreateFinancialStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_statements do |t|
      t.references :asset, null: false, foreign_key: true
      t.string   :statement_type, null: false
      t.string   :period_type, null: false
      t.date     :fiscal_date_ending, null: false
      t.integer  :fiscal_year
      t.integer  :fiscal_quarter
      t.string   :currency, default: "USD"
      t.jsonb    :data, null: false, default: {}
      t.string   :source
      t.datetime :fetched_at
      t.timestamps
    end

    add_index :financial_statements,
      [ :asset_id, :statement_type, :period_type, :fiscal_date_ending ],
      unique: true, name: "idx_fin_stmts_unique"
  end
end
