# Adaptive backoff for sync jobs. When a job encounters rate limiting
# or gateway failures, it increases the delay multiplier for subsequent
# runs. On success, the multiplier resets to 1x.
#
# State is stored in Rails.cache (Solid Cache in production, memory in test).
#
# Usage:
#   include AdaptiveScheduling
#
#   def perform
#     result = gateway.fetch(...)
#     if result.success?
#       adaptive_reset("polygon")
#     else
#       adaptive_backoff("polygon")
#     end
#   end
#
#   # Check current delay multiplier:
#   adaptive_multiplier("polygon")  # => 1, 2, or 4
#
module AdaptiveScheduling
  extend ActiveSupport::Concern

  MAX_MULTIPLIER = 4
  CACHE_TTL = 24.hours

  private

  def adaptive_backoff(provider_key)
    key = cache_key(provider_key)
    current = Rails.cache.read(key) || 1
    new_multiplier = [ current * 2, MAX_MULTIPLIER ].min
    Rails.cache.write(key, new_multiplier, expires_in: CACHE_TTL)
    new_multiplier
  end

  def adaptive_reset(provider_key)
    Rails.cache.write(cache_key(provider_key), 1, expires_in: CACHE_TTL)
    1
  end

  def adaptive_multiplier(provider_key)
    Rails.cache.read(cache_key(provider_key)) || 1
  end

  def cache_key(provider_key)
    "adaptive_sync:#{provider_key}"
  end
end
