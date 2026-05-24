require "rails_helper"

RSpec.describe "Webhooks::Resend", type: :request do
  # Known fixture secret in Svix's `whsec_<base64-key>` format.
  # The base64 portion decodes to the HMAC-SHA256 key used to sign payloads.
  let(:secret_key)    { "MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw" }
  let(:webhook_secret) { "whsec_#{Base64.strict_encode64(secret_key)}" }
  let(:svix_id)   { "msg_2ABC123" }
  let(:svix_ts)   { Time.current.to_i.to_s }
  let(:recipient) { "amigo@example.com" }
  let(:message_id) { "email_abc123" }

  let(:payload) do
    {
      type: "email.delivered",
      created_at: "2026-05-22T12:34:56.000Z",
      data: {
        email_id: message_id,
        to:       [ recipient ],
        from:     "noreply@stockerly.notdefined.dev",
        subject:  "Bienvenido"
      }
    }
  end
  let(:raw_body) { payload.to_json }

  def sign(body:, id: svix_id, ts: svix_ts, key: secret_key)
    signed_content = "#{id}.#{ts}.#{body}"
    digest = OpenSSL::HMAC.digest("SHA256", key, signed_content)
    "v1,#{Base64.strict_encode64(digest)}"
  end

  def post_webhook(body: raw_body, headers: {})
    post "/webhooks/resend",
         params:  body,
         headers: { "Content-Type" => "application/json" }.merge(headers)
  end

  around do |example|
    original = ENV["RESEND_WEBHOOK_SECRET"]
    ENV["RESEND_WEBHOOK_SECRET"] = webhook_secret
    example.run
  ensure
    ENV["RESEND_WEBHOOK_SECRET"] = original
  end

  describe "POST /webhooks/resend" do
    context "with a valid signature" do
      it "returns 200 and persists the event with all fields populated" do
        expect {
          post_webhook(headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => svix_ts,
            "Svix-Signature" => sign(body: raw_body)
          })
        }.to change(EmailEvent, :count).by(1)

        expect(response).to have_http_status(:ok)

        row = EmailEvent.last
        expect(row.email).to       eq(recipient)
        expect(row.event_type).to  eq("delivered")
        expect(row.message_id).to  eq(message_id)
        expect(row.occurred_at).to be_within(1.second).of(Time.zone.parse("2026-05-22T12:34:56.000Z"))
        expect(row.raw_payload).to include("type" => "email.delivered")
      end

      it "accepts multiple Resend event types" do
        %w[email.sent email.bounced email.opened email.clicked email.complained].each_with_index do |type, idx|
          body = payload.merge(type: type, data: payload[:data].merge(email_id: "msg_#{idx}")).to_json
          post_webhook(body: body, headers: {
            "Svix-Id"        => "msg_#{idx}",
            "Svix-Timestamp" => svix_ts,
            "Svix-Signature" => sign(body: body, id: "msg_#{idx}")
          })
          expect(response).to have_http_status(:ok), "expected ok for #{type}, got #{response.status}"
        end

        expect(EmailEvent.distinct.pluck(:event_type)).to match_array(%w[sent bounced opened clicked complained])
      end

      it "is idempotent on (message_id, event_type) — retried webhooks create no duplicate rows" do
        headers = {
          "Svix-Id"        => svix_id,
          "Svix-Timestamp" => svix_ts,
          "Svix-Signature" => sign(body: raw_body)
        }
        post_webhook(headers: headers)
        expect(EmailEvent.count).to eq(1)

        expect {
          post_webhook(headers: headers)
        }.not_to change(EmailEvent, :count)
        expect(response).to have_http_status(:ok)
      end

      it "ignores unknown event types without raising" do
        body = payload.merge(type: "email.dispatched").to_json
        expect {
          post_webhook(body: body, headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => svix_ts,
            "Svix-Signature" => sign(body: body)
          })
        }.not_to change(EmailEvent, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid signature" do
      it "returns 401 and creates no row" do
        expect {
          post_webhook(headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => svix_ts,
            "Svix-Signature" => "v1,#{Base64.strict_encode64('not-the-real-signature')}"
          })
        }.not_to change(EmailEvent, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no signature header" do
      it "returns 401 and creates no row" do
        expect {
          post_webhook(headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => svix_ts
          })
        }.not_to change(EmailEvent, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a stale timestamp (replay attempt)" do
      it "returns 401 even with an otherwise-valid signature" do
        stale_ts = (Time.current - 1.hour).to_i.to_s
        expect {
          post_webhook(headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => stale_ts,
            "Svix-Signature" => sign(body: raw_body, ts: stale_ts)
          })
        }.not_to change(EmailEvent, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when RESEND_WEBHOOK_SECRET is unset" do
      it "returns 401 even for a signature that would otherwise verify" do
        ENV["RESEND_WEBHOOK_SECRET"] = nil
        expect {
          post_webhook(headers: {
            "Svix-Id"        => svix_id,
            "Svix-Timestamp" => svix_ts,
            "Svix-Signature" => sign(body: raw_body)
          })
        }.not_to change(EmailEvent, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
