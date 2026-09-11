class AssetFundamental < ApplicationRecord
  belongs_to :asset

  validates :period_label, presence: true
  validates :metrics, presence: true

  scope :for_asset, ->(asset_id) { where(asset_id: asset_id) }
  scope :overview, -> { where(period_label: "OVERVIEW") }
  scope :ttm, -> { where(period_label: "TTM") }
  scope :latest, -> { order(calculated_at: :desc) }

  # Best first: the statements calculator's row, then the provider's overview filling its gaps (D116).
  def self.for_reading(asset)
    labels = asset.asset_type_crypto? ? %w[CRYPTO_MARKET] : %w[CALCULATED OVERVIEW]
    labels.filter_map { |label| asset.asset_fundamentals.where(period_label: label).latest.first }
  end
end
