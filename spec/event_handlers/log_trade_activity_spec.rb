require "rails_helper"

RSpec.describe LogTradeActivity do
  describe ".call" do
    let(:user) { create(:user) }
    let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
    let(:asset) { create(:asset) }
    let(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90) }
    let(:trade) { create(:trade, portfolio: portfolio, asset: asset, position: position, side: :buy, shares: 5, price_per_share: 100) }

    it "creates an AuditLog" do
      expect {
        described_class.call(user_id: user.id, trade_id: trade.id, side: "buy", shares: "5")
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("trade_buy")
      expect(log.user).to eq(user)
      expect(log.auditable).to eq(trade)
    end
  end
end
