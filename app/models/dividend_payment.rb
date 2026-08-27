class DividendPayment < ApplicationRecord
  belongs_to :portfolio
  belongs_to :dividend

  validates :shares_held,   presence: true, numericality: { greater_than: 0 }
  validates :total_amount,  presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Derived rather than stored: the money lands on the dividend's pay_date, and
  # a received_at column that nothing wrote made every payment look projected
  # forever (#305).
  def received?
    dividend.pay_date.present? && dividend.pay_date <= Date.current
  end
end
