class PortfolioSnapshot < ApplicationRecord
  belongs_to :portfolio

  validates :date,           presence: true, uniqueness: { scope: :portfolio_id }
  validates :total_value,    presence: true
  validates :cash_value,     presence: true
  validates :invested_value, presence: true

  scope :recent, -> { order(date: :desc) }
end
