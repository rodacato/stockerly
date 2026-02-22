class Dividend < ApplicationRecord
  belongs_to :asset
  has_many   :dividend_payments, dependent: :destroy

  validates :ex_date,          presence: true, uniqueness: { scope: :asset_id }
  validates :amount_per_share, presence: true, numericality: { greater_than: 0 }

  scope :upcoming, -> { where("ex_date >= ?", Date.current).order(:ex_date) }
end
