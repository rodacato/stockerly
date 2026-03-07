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

  def self.enabled?(key)
    get(key) == "true"
  end

  def self.registration_open?
    enabled?("registration_open")
  end
end
