class DividendPayment < ApplicationRecord
  belongs_to :portfolio
  belongs_to :dividend

  validates :shares_held,   presence: true, numericality: { greater_than: 0 }
  validates :total_amount,  presence: true

  scope :recent, -> { order(created_at: :desc) }
end
