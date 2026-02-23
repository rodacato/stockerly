class AssetFundamental < ApplicationRecord
  belongs_to :asset

  validates :period_label, presence: true
  validates :metrics, presence: true

  scope :for_asset, ->(asset_id) { where(asset_id: asset_id) }
  scope :overview, -> { where(period_label: "OVERVIEW") }
  scope :ttm, -> { where(period_label: "TTM") }
  scope :latest, -> { order(calculated_at: :desc) }
end
