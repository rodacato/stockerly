require "rails_helper"

RSpec.describe UserActivity, type: :model do
  subject(:activity) { build(:user_activity) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires action" do
      activity.action = nil
      expect(activity).not_to be_valid
      expect(activity.errors[:action]).to be_present
    end

    it "requires occurred_at" do
      activity.occurred_at = nil
      expect(activity).not_to be_valid
      expect(activity.errors[:occurred_at]).to be_present
    end

    it "requires a user" do
      activity.user = nil
      expect(activity).not_to be_valid
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:older) { create(:user_activity, user: user, action: "trade_executed",       occurred_at: 2.days.ago) }
    let!(:newer) { create(:user_activity, user: user, action: "page_view:dashboard#show", occurred_at: 1.hour.ago) }
    let!(:other) { create(:user_activity, user: create(:user), action: "trade_executed", occurred_at: 30.minutes.ago) }

    it ".recent orders by occurred_at desc" do
      expect(UserActivity.recent.first).to eq(other)
      expect(UserActivity.recent.last).to eq(older)
    end

    it ".by_action filters by action" do
      expect(UserActivity.by_action("trade_executed")).to contain_exactly(older, other)
    end

    it ".by_action returns all when name is nil" do
      expect(UserActivity.by_action(nil).count).to eq(3)
    end
  end

  describe "jsonb params" do
    it "round-trips arbitrary keys" do
      created = UserActivity.create!(
        user: create(:user),
        action: "trade_executed",
        params: { "asset_symbol" => "AAPL", "side" => "buy", "shares" => "10" },
        occurred_at: Time.current
      )

      reloaded = UserActivity.find(created.id)
      expect(reloaded.params).to eq("asset_symbol" => "AAPL", "side" => "buy", "shares" => "10")
    end

    it "defaults to empty hash" do
      activity = UserActivity.create!(user: create(:user), action: "x", occurred_at: Time.current)
      expect(activity.params).to eq({})
    end
  end
end
