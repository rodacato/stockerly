class WidenShareQuantitiesForCrypto < ActiveRecord::Migration[8.1]
  # Six decimals cannot hold a crypto quantity. A $10 buy of BTC at $103,472 is
  # 0.000096644 coins, which rounds to 0.000097 and misstates the trade by
  # 0.37% -- and a satoshi (0.00000001 BTC) has no representation at all.
  # Twelve covers Bitcoin's eight and the nine decimals Alpaca reports for
  # fractional shares, with room left over.
  COLUMNS = {
    trades: :shares,
    positions: :shares,
    dividend_payments: :shares_held
  }.freeze

  def up
    COLUMNS.each { |table, column| change_column table, column, :decimal, precision: 24, scale: 12, null: false }
  end

  def down
    COLUMNS.each { |table, column| change_column table, column, :decimal, precision: 15, scale: 6, null: false }
  end
end
