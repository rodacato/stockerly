class TechnicalReading < ApplicationRecord
  belongs_to :asset

  validates :calculated_at, presence: true
  validates :asset_id, uniqueness: true

  def [](key)
    readings[key.to_s]
  end

  def stale?(now = Time.current)
    calculated_at.to_date < now.to_date
  end
end
