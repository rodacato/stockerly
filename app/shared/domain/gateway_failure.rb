# The failure vocabulary every market-data gateway speaks.
#
# Before this, 66 call sites mapped 429 to :rate_limited and everything else to
# :gateway_error, so *no entitlement*, *endpoint retired*, *bad credential* and
# *transient outage* were indistinguishable. That single fact is what let a
# permanent denial be retried forever and a blocked provider look like a blip.
module GatewayFailure
  # Failures that will not succeed on retry with the same request. Retrying
  # them spends quota to be told no again.
  PERMANENT = %i[unauthorized no_entitlement endpoint_retired not_supported invalid_request].freeze

  STATUS_TAGS = {
    400 => :invalid_request,
    401 => :unauthorized,
    402 => :no_entitlement,
    403 => :no_entitlement,
    404 => :not_found,
    409 => :invalid_request,
    410 => :endpoint_retired,
    422 => :invalid_request,
    429 => :rate_limited
  }.freeze

  def self.permanent?(tag)
    PERMANENT.include?(tag&.to_sym)
  end

  # Builds the failure tuple for a non-success HTTP response.
  def self.from(response, provider)
    tag = STATUS_TAGS.fetch(response.status, :gateway_error)
    Dry::Monads::Failure([ tag, message_for(response, provider, tag) ])
  end

  def self.message_for(response, provider, tag)
    detail = detail_from(response.body)
    base = "#{provider}: #{tag} (HTTP #{response.status})"
    detail.present? ? "#{base} — #{detail}" : base
  end

  # Providers put their explanation in different keys; the useful ones are
  # short, so anything long is left out rather than truncated into noise.
  def self.detail_from(body)
    return nil unless body.is_a?(Hash)

    detail = body["message"] || body["error"] || body["Error"] || body["Note"] || body["Information"]
    detail = detail.values.flatten.join(", ") if detail.is_a?(Hash)
    detail = detail.join(", ") if detail.is_a?(Array)
    detail.to_s.strip.presence&.truncate(160)
  end
end
