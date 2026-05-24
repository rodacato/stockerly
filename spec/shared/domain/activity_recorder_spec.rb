require "rails_helper"

RSpec.describe ActivityRecorder do
  describe ".call" do
    let(:user) { create(:user) }

    it "creates a UserActivity row with the given attributes" do
      expect {
        described_class.call(user: user, action: "trade_executed", params: { asset_symbol: "AAPL", side: "buy", shares: "5" })
      }.to change(UserActivity, :count).by(1)

      activity = UserActivity.last
      expect(activity.user).to eq(user)
      expect(activity.action).to eq("trade_executed")
      expect(activity.params).to eq("asset_symbol" => "AAPL", "side" => "buy", "shares" => "5")
      expect(activity.occurred_at).to be_within(2.seconds).of(Time.current)
    end

    it "stamps occurred_at automatically when not provided" do
      described_class.call(user: user, action: "x")
      expect(UserActivity.last.occurred_at).to be_within(2.seconds).of(Time.current)
    end

    it "defaults params to empty hash when not provided" do
      described_class.call(user: user, action: "x")
      expect(UserActivity.last.params).to eq({})
    end

    it "no-ops and returns nil when user is nil" do
      expect {
        result = described_class.call(user: nil, action: "page_view:dashboard#show")
        expect(result).to be_nil
      }.not_to change(UserActivity, :count)
    end

    it "coerces a symbol action to a string" do
      described_class.call(user: user, action: :trade_executed)
      expect(UserActivity.last.action).to eq("trade_executed")
    end

    it "tolerates a nil params argument" do
      expect {
        described_class.call(user: user, action: "x", params: nil)
      }.to change(UserActivity, :count).by(1)
      expect(UserActivity.last.params).to eq({})
    end

    it "swallows ActiveRecord errors and returns nil" do
      allow(UserActivity).to receive(:create!).and_raise(ActiveRecord::StatementInvalid.new("boom"))
      expect(Rails.logger).to receive(:error).with(/ActivityRecorder/)
      expect(described_class.call(user: user, action: "x")).to be_nil
    end
  end
end
