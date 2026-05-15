class AddCurrencyToPortfolioSnapshots < ActiveRecord::Migration[8.1]
  def up
    add_column :portfolio_snapshots, :currency, :string

    # Backfill: each snapshot belongs to a portfolio belongs to a user.
    # Existing snapshots were written before currency was tracked; the
    # only safe assumption is they were in the user's preferred_currency
    # at the time of write (the value the dashboard would have rendered).
    execute <<~SQL
      UPDATE portfolio_snapshots
      SET currency = users.preferred_currency
      FROM portfolios, users
      WHERE portfolio_snapshots.portfolio_id = portfolios.id
        AND portfolios.user_id = users.id
    SQL

    change_column_null :portfolio_snapshots, :currency, false
    change_column_default :portfolio_snapshots, :currency, "USD"
  end

  def down
    remove_column :portfolio_snapshots, :currency
  end
end
