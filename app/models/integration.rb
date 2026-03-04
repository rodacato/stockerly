class Integration < ApplicationRecord
  enum :connection_status, { connected: 0, syncing: 1, disconnected: 2 }

  has_many :api_key_pools, dependent: :destroy

  validates :provider_name, presence: true, uniqueness: true
  validates :provider_type, presence: true
  encrypts :api_key_encrypted

  def increment_api_calls!
    reset_daily_counter! if calls_reset_at.nil? || calls_reset_at < Time.current.beginning_of_day
    return false if daily_api_calls >= daily_call_limit

    self.class.update_counters(id, daily_api_calls: 1)
    reload
    true
  end

  def budget_exhausted?
    return false if calls_reset_at.nil? || calls_reset_at < Time.current.beginning_of_day

    daily_api_calls >= daily_call_limit
  end

  def minute_budget_exhausted?
    return false if max_requests_per_minute.nil?
    return false if minute_reset_at.nil? || minute_reset_at < 1.minute.ago

    minute_calls >= max_requests_per_minute
  end

  def increment_minute_calls!
    reset_minute_counter! if minute_reset_at.nil? || minute_reset_at < 1.minute.ago
    self.class.update_counters(id, minute_calls: 1)
  end

  def reset_minute_counter!
    update!(minute_calls: 0, minute_reset_at: Time.current)
  end

  def setting(key)
    settings&.dig(key.to_s)
  end

  def active_api_key
    pool = api_key_pools.enabled.default_key.first || api_key_pools.enabled.least_used.first
    pool&.api_key_encrypted || api_key_encrypted
  end

  def api_key_configured?
    api_key_pools.enabled.exists? || api_key_encrypted.present?
  end

  def masked_api_key
    key = active_api_key
    return nil unless key.present?
    "••••••••••••#{key.last(4)}"
  end

  private

  def reset_daily_counter!
    update!(daily_api_calls: 0, calls_reset_at: Time.current)
  end
end
