class DropReceivedAtFromDividendPayments < ActiveRecord::Migration[8.1]
  # Nothing in app/ ever wrote it, so on every real instance the column is null
  # and "projected" and "received" are indistinguishable in the data (#305).
  # Whether a payment has landed is a function of the dividend's pay_date, so
  # DividendPayment#received? derives it instead.
  def change
    remove_column :dividend_payments, :received_at, :datetime
  end
end
