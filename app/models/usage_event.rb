# ADR-032: one catalogued event. Written only through Usage.record.
class UsageEvent < ApplicationRecord
  RETENTION = 90.days

  scope :stale_before, ->(time) { where(occurred_at: ...time) }

  def self.purge_stale!(now = Time.current)
    stale_before(now - RETENTION).delete_all
  end
end
