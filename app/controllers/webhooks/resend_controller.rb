module Webhooks
  # Receives Resend webhook deliveries and persists each event to the
  # `email_events` table for ops queries (did the beta amigo get the invite,
  # did anyone bounce, etc — see docs/ops/beta-support.md §8).
  #
  # Resend uses Svix-style HMAC-SHA256 signatures. The signed string is
  # "<svix-id>.<svix-timestamp>.<raw_body>" and the key is the base64-decoded
  # portion of RESEND_WEBHOOK_SECRET after the `whsec_` prefix.
  # Reference: https://docs.svix.com/receiving/verifying-payloads/how-manual
  #
  # No business logic lives here — just verify, parse, persist. Downstream
  # consumers can subscribe via ActiveSupport::Notifications if needed later.
  class ResendController < ActionController::Base
    # Webhook tolerance window: drop signatures whose timestamp is more than
    # 5 minutes off, to prevent replay attacks.
    TIMESTAMP_TOLERANCE = 5.minutes

    def create
      raw_body = request.body.read

      unless signature_valid?(raw_body)
        head :unauthorized
        return
      end

      payload = JSON.parse(raw_body)
      persist_event(payload)
      render json: {}, status: :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def signature_valid?(raw_body)
      secret    = ENV["RESEND_WEBHOOK_SECRET"]
      svix_id   = request.headers["Svix-Id"]
      svix_ts   = request.headers["Svix-Timestamp"]
      svix_sig  = request.headers["Svix-Signature"]

      return false if secret.blank? || svix_id.blank? || svix_ts.blank? || svix_sig.blank?
      return false unless timestamp_within_tolerance?(svix_ts)

      key = decode_secret(secret)
      return false unless key

      signed_content = "#{svix_id}.#{svix_ts}.#{raw_body}"
      expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, signed_content))

      # Header may contain space-separated "v1,sig1 v1,sig2" pairs — accept any v1 match.
      svix_sig.split(" ").any? do |entry|
        version, sig = entry.split(",", 2)
        next false unless version == "v1" && sig.present?

        ActiveSupport::SecurityUtils.secure_compare(expected, sig)
      end
    end

    def timestamp_within_tolerance?(svix_ts)
      ts = Integer(svix_ts)
      (Time.current.to_i - ts).abs <= TIMESTAMP_TOLERANCE.to_i
    rescue ArgumentError, TypeError
      false
    end

    def decode_secret(secret)
      _, encoded = secret.split("_", 2)
      return nil if encoded.blank?

      Base64.decode64(encoded)
    end

    def persist_event(payload)
      type = payload["type"].to_s.sub(/\Aemail\./, "")
      return unless EmailEvent::EVENT_TYPES.include?(type)

      data       = payload["data"] || {}
      message_id = data["email_id"].presence
      recipient  = Array(data["to"]).first
      occurred   = parse_time(payload["created_at"]) || Time.current

      return if recipient.blank?

      attrs = {
        email:       recipient,
        event_type:  type,
        message_id:  message_id,
        occurred_at: occurred,
        raw_payload: payload
      }

      if message_id.present?
        # Idempotent on (message_id, event_type) — Resend retries duplicate webhooks
        # until they get a 2xx, so we MUST swallow duplicates rather than 409.
        EmailEvent.find_or_create_by!(message_id: message_id, event_type: type) do |row|
          row.assign_attributes(attrs)
        end
      else
        EmailEvent.create!(attrs)
      end
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
