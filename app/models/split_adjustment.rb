# What Trading has already applied, so a re-delivered SplitDetected is a no-op.
# Trading's own bookkeeping: it used to live on `stock_splits.applied_at`, a
# table MarketData owns, which is what made the handler resolve a foreign row.
class SplitAdjustment < ApplicationRecord
  belongs_to :asset

  validates :ex_date, presence: true
  validates :ratio_from, presence: true, numericality: { greater_than: 0 }
  validates :ratio_to, presence: true, numericality: { greater_than: 0 }
end
