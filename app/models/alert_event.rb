class AlertEvent < ApplicationRecord
  belongs_to :alert_rule, optional: true
  belongs_to :user

  enum :event_status, { triggered: 0, settled: 1 }

  validates :asset_symbol, presence: true
  validates :message,      presence: true
  validates :triggered_at, presence: true

  scope :recent, -> { order(triggered_at: :desc).limit(10) }
end
