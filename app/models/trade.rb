class Trade < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  belongs_to :position, optional: true

  enum :side, { buy: 0, sell: 1 }

  validates :shares,          presence: true, numericality: { greater_than: 0 }
  validates :price_per_share, presence: true, numericality: { greater_than: 0 }
  validates :total_amount,    presence: true
  validates :executed_at,     presence: true

  before_validation :calculate_total_amount, on: :create

  scope :buys,  -> { where(side: :buy) }
  scope :sells, -> { where(side: :sell) }
  scope :recent, -> { order(executed_at: :desc) }

  private

  def calculate_total_amount
    self.total_amount = (shares || 0) * (price_per_share || 0)
  end
end
