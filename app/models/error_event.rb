class ErrorEvent < ApplicationRecord
  SOURCES = %w[request job other].freeze
  RETENTION = 30.days

  validates :fingerprint,     presence: true, uniqueness: true
  validates :exception_class, presence: true
  validates :source,          inclusion: { in: SOURCES }

  scope :recent,       -> { order(last_seen_at: :desc) }
  scope :since,        ->(time) { where("last_seen_at >= ?", time) }
  scope :stale_before, ->(time) { where("last_seen_at < ?", time) }
  scope :by_source,    ->(source) { where(source: source) if source.present? }

  # Called from config/recurring.yml. Nobody runs maintenance on their own
  # self-hosted box, so the table bounds itself.
  def self.purge_stale!(now = Time.current)
    stale_before(now - RETENTION).delete_all
  end
end
