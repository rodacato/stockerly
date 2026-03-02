# Proactive rate limiter for external API providers.
# Checks per-minute and per-day quotas before HTTP calls are made.
# Returns Success(:allowed) or Failure([:rate_limited, message]).
#
# Usage:
#   RateLimiter.check!("Polygon.io")  # => Success(:allowed)
#   RateLimiter.check!("Polygon.io")  # => Failure([:rate_limited, "..."])
#
class RateLimiter
  include Dry::Monads[:result]

  def self.check!(provider_name)
    new.check!(provider_name)
  end

  def check!(provider_name)
    integration = Integration.find_by(provider_name: provider_name)
    return Success(:allowed) unless integration

    # Check per-minute limit
    if integration.max_requests_per_minute.present?
      if integration.minute_budget_exhausted?
        return Failure([:rate_limited, "#{provider_name}: minute limit reached (#{integration.max_requests_per_minute}/min)"])
      end
    end

    # Check per-day limit
    if integration.budget_exhausted?
      return Failure([:rate_limited, "#{provider_name}: daily limit reached (#{integration.daily_call_limit}/day)"])
    end

    # Increment counters
    integration.increment_minute_calls! if integration.max_requests_per_minute.present?
    integration.increment_api_calls!

    Success(:allowed)
  end
end
