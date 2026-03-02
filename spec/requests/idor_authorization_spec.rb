require "rails_helper"

RSpec.describe "IDOR authorization", type: :request do
  let!(:user_a) { create(:user, email: "user_a@example.com", password: "password123") }
  let!(:user_b) { create(:user, email: "user_b@example.com", password: "password123") }

  before { login_as(user_a) }

  describe "Watchlist" do
    let!(:item_b) { create(:watchlist_item, user: user_b, asset: create(:asset)) }

    it "prevents deleting another user's watchlist item" do
      expect {
        delete watchlist_item_path(item_b)
      }.not_to change(WatchlistItem, :count)
    end
  end

  describe "Alerts" do
    let!(:rule_b) { create(:alert_rule, user: user_b) }

    it "prevents updating another user's alert rule" do
      patch alert_path(rule_b), params: { alert: { threshold_value: 999.0 } }
      expect(rule_b.reload.threshold_value).not_to eq(999.0)
    end

    it "prevents deleting another user's alert rule" do
      expect {
        delete alert_path(rule_b)
      }.not_to change(AlertRule, :count)
    end

    it "prevents toggling another user's alert rule" do
      original_status = rule_b.status
      patch toggle_alert_path(rule_b)
      expect(rule_b.reload.status).to eq(original_status)
    end
  end

  describe "Notifications" do
    let!(:notification_b) { create(:notification, user: user_b, read: false) }

    it "prevents marking another user's notification as read" do
      patch mark_as_read_notification_path(notification_b)
      expect(notification_b.reload.read).to be false
    end
  end

  describe "Trades" do
    let!(:portfolio_b) { create(:portfolio, user: user_b) }
    let!(:asset) { create(:asset, :stock, symbol: "TSLA") }
    let!(:trade_b) do
      create(:trade, portfolio: portfolio_b, asset: asset, side: :buy,
             shares: 10.0, price_per_share: 200.0, executed_at: 2.days.ago)
    end

    it "prevents editing another user's trade" do
      get edit_trade_path(trade_b)
      expect(response).to redirect_to(trades_path)
    end

    it "prevents updating another user's trade" do
      patch trade_path(trade_b), params: { trade: { shares: "99" } }
      expect(trade_b.reload.shares).to eq(10.0)
    end

    it "prevents deleting another user's trade" do
      delete trade_path(trade_b)
      expect(trade_b.reload.discarded_at).to be_nil
    end
  end
end
