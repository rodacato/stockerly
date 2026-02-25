require "rails_helper"

RSpec.describe LogTradeDelete do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, symbol: "AAPL") }
  let!(:trade) do
    create(:trade, portfolio: portfolio, asset: asset,
           side: :buy, shares: 10.0, price_per_share: 150.0,
           total_amount: 1500.0, executed_at: Time.current)
  end

  it "creates an audit log entry for the trade deletion" do
    event = TradeDeleted.new(
      trade_id: trade.id,
      user_id: user.id,
      position_id: 0
    )

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.action).to eq("trade_deleted")
    expect(log.user_id).to eq(user.id)
    expect(log.auditable).to eq(trade)
  end
end
