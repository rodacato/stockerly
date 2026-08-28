class SiteConfig < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.get(key, default: nil)
    find_by(key: key)&.value || default
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.update!(value: value.to_s)
  end

  # An absent row means the setting was never touched, which is not the same as
  # off. auto_sync_enabled and email_notifications_enabled default to on, so
  # wiring them does not silently stop an instance that predates the switch.
  def self.enabled?(key, default: false)
    value = get(key)
    return default if value.nil?

    value == "true"
  end

  def self.maintenance_mode?
    enabled?("maintenance_mode")
  end

  def self.developer_mode?
    enabled?("developer_mode")
  end
end
