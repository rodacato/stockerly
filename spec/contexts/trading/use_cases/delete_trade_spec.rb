require "rails_helper"

RSpec.describe Trading::UseCases::DeleteTrade do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL") }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }
  let!(:trade) do
    create(:trade, portfolio: portfolio, asset: asset, position: position,
           side: :buy, shares: 10.0, price_per_share: 150.0, total_amount: 1500.0,
           executed_at: 5.days.ago)
  end

  describe "successful soft delete" do
    it "sets discarded_at on the trade" do
      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_success
      trade.reload
      expect(trade.discarded?).to be true
      expect(trade.discarded_at).to be_within(5.seconds).of(Time.current)
    end

    it "recalculates position to zero shares and closes it" do
      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(0.0)
      expect(position.status).to eq("closed")
    end

    it "recalculates position correctly with remaining trades" do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
             side: :buy, shares: 5.0, price_per_share: 160.0, total_amount: 800.0,
             executed_at: 3.days.ago)

      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(5.0)
      expect(position.status).to eq("open")
    end
  end

  describe "30-day delete guard" do
    it "rejects deletion of trades older than 30 days" do
      trade.update_column(:executed_at, 31.days.ago)

      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_failure
      expect(result.failure).to eq([ :too_old, "Cannot delete trades older than 30 days" ])
    end
  end

  describe "authorization" do
    it "rejects deletion from non-owner" do
      other_user = create(:user, email: "other@test.com")
      create(:portfolio, user: other_user)

      result = described_class.call(user: other_user, trade_id: trade.id)

      expect(result).to be_failure
      expect(result.failure).to eq([ :unauthorized, "Not authorized to delete this trade" ])
    end
  end

  describe "idempotency" do
    it "rejects deletion of already discarded trade" do
      trade.discard!

      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_failure
      expect(result.failure).to eq([ :already_discarded, "Trade already deleted" ])
    end
  end

  describe "event publishing" do
    it "publishes TradeDeleted event" do
      handler = class_double(Trading::Handlers::LogTradeDelete, call: nil).as_stubbed_const
      EventBus.subscribe(Trading::Events::TradeDeleted, handler)

      result = described_class.call(user: user, trade_id: trade.id)

      expect(result).to be_success
      expect(handler).to have_received(:call).with(an_instance_of(Trading::Events::TradeDeleted))
    end
  end

  describe "not found" do
    it "fails when trade does not exist" do
      result = described_class.call(user: user, trade_id: 999999)

      expect(result).to be_failure
      expect(result.failure).to eq([ :not_found, "Trade not found" ])
    end
  end
end
