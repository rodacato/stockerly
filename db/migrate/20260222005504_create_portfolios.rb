class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios do |t|
      t.references :user,         null: false, foreign_key: true, index: { unique: true }
      t.decimal    :buying_power, null: false, precision: 15, scale: 2, default: 0
      t.date       :inception_date

      t.timestamps
    end
  end
end
