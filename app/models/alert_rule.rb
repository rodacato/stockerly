class AlertRule < ApplicationRecord
  belongs_to :user
  has_many   :alert_events, dependent: :nullify

  # `condition` mixes two evaluation cadences:
  #   * price/RSI/volume — evaluated on MarketData::Events::AssetPriceUpdated
  #   * dividend_ex_date — evaluated daily by Alerts::EvaluateDateBasedAlertsJob
  # See Alerts::Domain::AlertEvaluator and Alerts::Domain::DateBasedAlertEvaluator.
  enum :condition, {
    price_crosses_above: 0,
    price_crosses_below: 1,
    day_change_percent:  2,
    rsi_overbought:      3,
    rsi_oversold:        4,
    volume_spike:        7,
    dividend_ex_date:    8
  }
  enum :status, { active: 0, paused: 1 }

  DATE_BASED_CONDITIONS = %w[dividend_ex_date].freeze

  validates :asset_symbol,    presence: true
  validates :threshold_value, presence: true, numericality: true
  validates :window_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :date_based, -> { where(condition: DATE_BASED_CONDITIONS) }
  scope :price_based, -> { where.not(condition: DATE_BASED_CONDITIONS) }

  DEFAULT_COOLDOWN_MINUTES = 60

  # Symbol convention: `XXX.MX` for BMV-listed equities (priced in MXN); the
  # rest default to USD. Single source of truth for any code that needs to
  # format thresholds or pick a currency badge for an alert.
  def currency
    asset_symbol.to_s.match?(/\.MX\z/i) ? "MXN" : "USD"
  end

  def date_based?
    DATE_BASED_CONDITIONS.include?(condition)
  end

  def cooled_down?
    return true if last_triggered_at.nil?

    last_triggered_at < (cooldown_minutes || DEFAULT_COOLDOWN_MINUTES).minutes.ago
  end
end
