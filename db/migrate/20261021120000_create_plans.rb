class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :portfolio, null: false, foreign_key: true, index: { unique: true }
      t.integer :stocks_share, null: false
      t.integer :crypto_share, null: false
      t.integer :fixed_income_share, null: false
      t.decimal :monthly_contribution, precision: 15, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
