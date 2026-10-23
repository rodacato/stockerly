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

  describe "when another trade on the position was deleted" do
    let!(:discarded_trade) do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
             side: :buy, shares: 5.0, price_per_share: 100.0, total_amount: 500.0,
             executed_at: 4.days.ago, discarded_at: 1.hour.ago)
    end

    it "leaves the discarded trade out of the recalculated shares" do
      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 12.0 })

      expect(result).to be_success
      expect(position.reload.shares).to eq(12.0)
    end
  end

  # F2.3: editing a buy below what was later sold is refused whole.
  describe "an edit that would sell more than was bought" do
    before do
      create(:trade, portfolio: portfolio, asset: asset, position: position, side: :sell, shares: 8.0,
                     price_per_share: 160.0, total_amount: 1280.0, executed_at: 4.days.ago)
      position.resync_from_trades!
    end

    it "is refused, and leaves the trade and the position as they were" do
      result = described_class.call(user: user, params: { trade_id: trade.id, shares: 5.0 })

      expect(result.failure.first).to eq(:leaves_negative)
      expect(trade.reload.shares).to eq(10.0)
      expect(position.reload.shares).to eq(2.0)
    end
  end

  # F2.5: the edit row always posts the date; an emptied field means unchanged.
  it "keeps the date when the field comes back blank" do
    original = trade.executed_at

    described_class.call(user: user, params: { trade_id: trade.id, executed_at: "" })

    expect(trade.reload.executed_at).to be_within(1.second).of(original)
  end

  # F2.6: an emptied fee is no fee, not a NULL the column refuses.
  it "reads a blank fee as zero" do
    trade.update!(fee: 5)

    result = described_class.call(user: user, params: { trade_id: trade.id, fee: "" })

    expect(result).to be_success
    expect(trade.reload.fee).to eq(0)
  end
end
