class AlertRule < ApplicationRecord
  belongs_to :user
  has_many   :alert_events, dependent: :nullify

  enum :condition, {
    price_crosses_above: 0,
    price_crosses_below: 1,
    day_change_percent:  2,
    rsi_overbought:      3,
    rsi_oversold:        4,
    sentiment_above:     5,
    sentiment_below:     6,
    volume_spike:        7
  }
  enum :status, { active: 0, paused: 1 }

  validates :asset_symbol,    presence: true
  validates :threshold_value, presence: true, numericality: true

  def cooled_down?
    last_triggered_at.nil? || last_triggered_at < cooldown_minutes.minutes.ago
  end
end
