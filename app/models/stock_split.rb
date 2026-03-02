class StockSplit < ApplicationRecord
  belongs_to :asset

  validates :ex_date, presence: true, uniqueness: { scope: :asset_id }
  validates :ratio_from, presence: true, numericality: { greater_than: 0 }
  validates :ratio_to, presence: true, numericality: { greater_than: 0 }

  scope :recent, -> { order(ex_date: :desc) }

  def ratio
    ratio_to.to_f / ratio_from
  end

  def label
    "#{ratio_from}:#{ratio_to}"
  end
end
