# D26: buying_power was set to 0 at registration and never assigned again —
# no deposit, no withdrawal, no cash model, and ExecuteTrade never touched it.
# Three surfaces still presented it as meaningful, one of them deriving a
# percentage that was always exactly 100. The north star is investment
# patrimony (docs/vision/README.md), so the concept goes rather than grows.
class RemoveDeadCashConcept < ActiveRecord::Migration[8.1]
  def up
    guard_against_real_balances!

    remove_column :portfolios, :buying_power
    remove_column :portfolio_snapshots, :cash_value
  end

  def down
    add_column :portfolios, :buying_power, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :portfolio_snapshots, :cash_value, :decimal, precision: 15, scale: 2, null: false, default: 0
  end

  private

  # Nothing in the codebase writes these, but an instance whose owner set a
  # balance by hand in the console would lose it silently. Dropping money
  # columns is irreversible, so a surprise stops the migration instead of
  # being discarded.
  def guard_against_real_balances!
    portfolios = select_value("SELECT COUNT(*) FROM portfolios WHERE buying_power <> 0").to_i
    snapshots  = select_value("SELECT COUNT(*) FROM portfolio_snapshots WHERE cash_value <> 0").to_i
    return if portfolios.zero? && snapshots.zero?

    raise <<~MESSAGE
      Refusing to drop the cash columns: #{portfolios} portfolio(s) and #{snapshots} snapshot(s) hold a non-zero balance.

      D26 assumed these are always zero because no code writes them. This instance
      disagrees, so the data is real and the decision needs revisiting — see
      design/DECISIONS.md D26. Zero them deliberately, or reopen the decision.
    MESSAGE
  end
end
