class TechnicalObservation < ApplicationRecord
  belongs_to :asset

  # Closed set of detectable transitions (#40 JTBD #6). Adding a new type
  # requires both the detector logic and a presentation entry in MarketHelper
  # (phrase / tag / accent).
  TYPES = %w[
    rsi_oversold_entered
    rsi_overbought_entered
    rsi_oversold_exited
    rsi_overbought_exited
    ma200_crossed_above
    ma200_crossed_below
    ma50_crossed_above
    ma50_crossed_below
    bb_upper_breached
    bb_lower_breached
  ].freeze

  validates :observation_type, presence: true, inclusion: { in: TYPES }
  validates :observed_at, presence: true

  scope :recent, -> { order(observed_at: :desc) }
  scope :within_last, ->(days) { where(observed_at: days.days.ago..) }
  scope :for_assets, ->(asset_ids) { where(asset_id: asset_ids) }
end
