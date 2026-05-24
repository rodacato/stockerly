require "rails_helper"

RSpec.describe Trading::Handlers::RecordTradeActivity do
  describe ".call" do
    let(:user)      { create(:user) }
    let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
    let(:asset)     { create(:asset, symbol: "AAPL") }
    let(:position)  { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90) }
    let(:trade)    { create(:trade, portfolio: portfolio, asset: asset, position: position, side: :buy, shares: 5, price_per_share: 100) }

    it "records a trade_executed activity with symbol + side + shares" do
      event = Trading::Events::TradeExecuted.new(
        trade_id: trade.id, user_id: user.id, position_id: position.id, side: "buy", shares: "5"
      )

      expect {
        described_class.call(event)
      }.to change(UserActivity, :count).by(1)

      activity = UserActivity.last
      expect(activity.user).to eq(user)
      expect(activity.action).to eq("trade_executed")
      expect(activity.params).to eq("asset_symbol" => "AAPL", "side" => "buy", "shares" => "5")
    end

    it "accepts a serialized hash event from ProcessEventJob" do
      hash_event = { user_id: user.id, trade_id: trade.id, side: "sell", shares: "3" }

      expect {
        described_class.call(hash_event)
      }.to change(UserActivity, :count).by(1)

      expect(UserActivity.last.params).to include("side" => "sell", "shares" => "3")
    end

    it "no-ops if the trade no longer exists" do
      event = Trading::Events::TradeExecuted.new(
        trade_id: 999_999_999, user_id: user.id, position_id: position.id, side: "buy", shares: "5"
      )

      expect {
        described_class.call(event)
      }.not_to change(UserActivity, :count)
    end

    it "subscribes via EventBus and fires on TradeExecuted publish" do
      load Rails.root.join("config/initializers/event_subscriptions.rb")

      expect {
        EventBus.publish(Trading::Events::TradeExecuted.new(
          trade_id: trade.id, user_id: user.id, position_id: position.id, side: "buy", shares: "5"
        ))
      }.to change(UserActivity.by_action("trade_executed"), :count).by(1)
    end
  end
end
