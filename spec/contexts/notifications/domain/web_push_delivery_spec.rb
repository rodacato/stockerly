require "rails_helper"

RSpec.describe Notifications::Domain::WebPushDelivery do
  let(:subscription) { create(:push_subscription) }

  def deliver
    described_class.call(subscription: subscription, title: "AAPL", body: "cruzó 180",
                         path: "/notifications", badge_count: 3)
  end

  # WebPush talks to the push service over the network, so it is the one thing
  # here that gets stubbed. Everything below it is the real record.
  context "with VAPID keys configured" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("public-key")
      allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("private-key")
    end

    # `.kamal/secrets` resolves every entry as `NAME=$NAME`, so a variable
    # nobody set ships as "" rather than absent — the same trap deploy.md
    # documents for the encryption keys. A push service rejects an empty
    # subject, so falling back on absence alone was not falling back at all.
    it "falls back to a default subject when the variable ships empty" do
      allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("")

      expect(WebPush).to receive(:payload_send) do |args|
        expect(args[:vapid][:subject]).to eq("mailto:stockerly@localhost")
      end

      deliver
    end

    it "prefers the subject the instance configured" do
      allow(ENV).to receive(:[]).with("VAPID_SUBJECT").and_return("mailto:you@example.com")

      expect(WebPush).to receive(:payload_send) do |args|
        expect(args[:vapid][:subject]).to eq("mailto:you@example.com")
      end

      deliver
    end

    it "encrypts the payload to the subscription and records the delivery" do
      expect(WebPush).to receive(:payload_send) do |args|
        expect(args[:endpoint]).to eq(subscription.endpoint)
        expect(JSON.parse(args[:message])).to include("title" => "AAPL", "badge" => 3)
      end

      expect(deliver).to be(true)
      expect(subscription.reload.last_delivered_at).to be_present
    end

    # A dead endpoint retried forever is the failure mode this prevents.
    it "drops a subscription the browser has expired" do
      gone = WebPush::ExpiredSubscription.new(instance_double(Net::HTTPGone, body: "", code: "410"), "host")
      allow(WebPush).to receive(:payload_send).and_raise(gone)

      expect(deliver).to be(false)
      expect(PushSubscription.exists?(subscription.id)).to be(false)
    end

    # A key pair pasted wrong is a self-hoster's likeliest mistake, and it
    # would otherwise raise out of every alert and retry the queue forever.
    it "keeps a malformed key pair out of the job queue, and the subscription" do
      allow(WebPush).to receive(:payload_send).and_raise(WebPush::ConfigurationError, "invalid key")

      expect(deliver).to be(false)
      expect(PushSubscription.exists?(subscription.id)).to be(true)
    end
  end

  context "without VAPID keys" do
    # Stubbed rather than assumed: a developer with keys in their own .env used
    # to make this example pass for the wrong reason, and fail once they had.
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return(nil)
      allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return(nil)
    end

    it "reads as off rather than raising on every alert" do
      expect(WebPush).not_to receive(:payload_send)

      expect(described_class).not_to be_configured
      expect(deliver).to be(false)
    end
  end
end
