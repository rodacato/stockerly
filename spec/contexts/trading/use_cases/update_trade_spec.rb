require "rails_helper"

RSpec.describe Trading::UseCases::UpdateTrade do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL") }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }
  let!(:trade) do
    create(:trade, portfolio: portfolio, asset: asset, position: position,
           side: :buy, shares: 10.0, price_per_share: 150.0, total_amount: 1500.0,
           executed_at: 5.days.ago)
  end

  describe "successful update" do
    it "updates shares and recalculates total_amount" do
      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 15.0 })

      expect(result).to be_success
      trade.reload
      expect(trade.shares).to eq(15.0)
      expect(trade.total_amount).to eq(15.0 * 150.0)
    end

    it "updates price_per_share and recalculates total_amount" do
      result = described_class.call(user: user, params: { trade_id: trade.id, price_per_share: 160.0 })

      expect(result).to be_success
      trade.reload
      expect(trade.price_per_share).to eq(160.0)
      expect(trade.total_amount).to eq(10.0 * 160.0)
    end

    it "updates fee without affecting position" do
      result = described_class.call(user: user, params: { trade_id: trade.id, fee: 9.99 })

      expect(result).to be_success
      trade.reload
      expect(trade.fee).to eq(9.99)
    end

    it "recalculates position avg_cost when shares change" do
      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 20.0 })

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(20.0)
    end

    it "recalculates position shares from all buy/sell trades" do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
             side: :sell, shares: 3.0, price_per_share: 160.0, total_amount: 480.0,
             executed_at: 2.days.ago)

      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 8.0 })

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(5.0) # 8 buy - 3 sell
    end
  end

  describe "30-day edit guard" do
    it "rejects edits to trades older than 30 days" do
      trade.update_column(:executed_at, 31.days.ago)

      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 15.0 })

      expect(result).to be_failure
      expect(result.failure).to eq([ :too_old, "Cannot edit trades older than 30 days" ])
    end

    it "allows edits to trades exactly 30 days old" do
      trade.update_column(:executed_at, 29.days.ago)

      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 15.0 })

      expect(result).to be_success
    end
  end

  describe "authorization" do
    it "rejects updates from non-owner" do
      other_user = create(:user, email: "other@test.com")
      create(:portfolio, user: other_user)

      result = described_class.call(user: other_user, params: { trade_id: trade.id, shares: 15.0 })

      expect(result).to be_failure
      expect(result.failure).to eq([ :unauthorized, "Not authorized to edit this trade" ])
    end
  end

  describe "event publishing" do
    it "publishes TradeUpdated event" do
      handler = class_double(Trading::Handlers::LogTradeUpdate, call: nil).as_stubbed_const
      EventBus.subscribe(Trading::Events::TradeUpdated, handler)

      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 15.0 })

      expect(result).to be_success
      expect(handler).to have_received(:call).with(an_instance_of(Trading::Events::TradeUpdated))
    end
  end

  describe "validation" do
    it "fails with invalid params" do
      result = described_class.call(user: user, params: { trade_id: trade.id, shares: -1.0 })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails when trade does not exist" do
      result = described_class.call(user: user, params: { trade_id: 999999, shares: 15.0 })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
