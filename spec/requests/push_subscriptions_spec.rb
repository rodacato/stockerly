require "rails_helper"

RSpec.describe "Push subscriptions", type: :request do
  let(:user) { create(:user) }
  let(:endpoint) { "https://fcm.googleapis.com/fcm/send/abc123" }
  let(:payload) do
    { push_subscription: { endpoint: endpoint, p256dh_key: "p256dh", auth_key: "auth" } }
  end

  before { login_as(user) }

  describe "POST" do
    it "records the install so an alert can be encrypted to it" do
      post push_subscriptions_path, params: payload, as: :json

      expect(response).to have_http_status(:created)
      expect(user.push_subscriptions.sole).to have_attributes(endpoint: endpoint, auth_key: "auth")
    end

    # Browsers re-issue the same endpoint with fresh keys after rotating them.
    it "refreshes the keys of an endpoint it already knows, without duplicating it" do
      create(:push_subscription, user: user, endpoint: endpoint, auth_key: "stale")

      post push_subscriptions_path, params: payload, as: :json

      expect(user.push_subscriptions.count).to eq(1)
      expect(user.push_subscriptions.sole.auth_key).to eq("auth")
    end

    it "rejects an endpoint that is not https" do
      post push_subscriptions_path, params: { push_subscription: payload[:push_subscription].merge(endpoint: "http://x") }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.push_subscriptions).to be_empty
    end
  end

  describe "DELETE" do
    it "forgets the install" do
      create(:push_subscription, user: user, endpoint: endpoint)

      delete push_subscriptions_path, params: { endpoint: endpoint }, as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.push_subscriptions).to be_empty
    end

    # The endpoint is guessable, so ownership has to be the filter, not the id.
    it "leaves another account's install alone" do
      other = create(:push_subscription, endpoint: endpoint)

      delete push_subscriptions_path, params: { endpoint: endpoint }, as: :json

      expect(PushSubscription.exists?(other.id)).to be(true)
    end
  end

  describe "the switch on /settings" do
    # A switch that cannot deliver is worse than no switch: it reports a state
    # the instance does not have. Most self-hosters will never set VAPID keys.
    it "is absent on an instance with no VAPID keys" do
      get settings_path

      expect(response.body).not_to include("push-subscription")
    end

    it "appears once the keys are configured" do
      allow(Notifications::Domain::WebPushDelivery).to receive(:configured?).and_return(true)
      allow(Notifications::Domain::WebPushDelivery).to receive(:public_key).and_return("public-key")

      get settings_path

      expect(response.body).to include('data-push-subscription-vapid-key-value="public-key"')
    end
  end

  it "turns anonymous callers away" do
    delete logout_path

    post push_subscriptions_path, params: payload, as: :json

    expect(response).to redirect_to(login_path)
  end
end
