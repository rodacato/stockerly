class TechnicalObservation < ApplicationRecord
  belongs_to :asset

  # Closed set of detectable transitions (#40 JTBD #6). Adding a new type
  # requires both the detector logic and a phrasing entry in the partial.
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

  # Descriptive label per ADR-001 — purely observational, no action verbs.
  # The asset symbol is rendered by the caller so this stays asset-agnostic.
  PHRASES = {
    "rsi_oversold_entered"   => "entered oversold zone (RSI(14) below 30)",
    "rsi_overbought_entered" => "entered overbought zone (RSI(14) above 70)",
    "rsi_oversold_exited"    => "exited oversold zone",
    "rsi_overbought_exited"  => "exited overbought zone",
    "ma200_crossed_above"    => "crossed above its MA200",
    "ma200_crossed_below"    => "crossed below its MA200",
    "ma50_crossed_above"     => "crossed above its MA50",
    "ma50_crossed_below"     => "crossed below its MA50",
    "bb_upper_breached"      => "broke its upper Bollinger Band",
    "bb_lower_breached"      => "broke its lower Bollinger Band"
  }.freeze

  def phrase
    PHRASES.fetch(observation_type, observation_type.humanize)
  end
end
