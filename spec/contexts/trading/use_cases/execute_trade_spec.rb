require "rails_helper"

RSpec.describe Trading::UseCases::ExecuteTrade do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL") }

  let(:buy_params) do
    {
      asset_symbol: "AAPL",
      side: "buy",
      shares: 10.0,
      price_per_share: 150.0
    }
  end

  describe "buy trades" do
    it "creates trade and new position when no open position" do
      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_success
      trade = result.value!
      expect(trade.side).to eq("buy")
      expect(trade.shares).to eq(10.0)
      expect(trade.price_per_share).to eq(150.0)
      expect(trade.position).to be_present
      expect(trade.position.status).to eq("open")
      expect(trade.position.shares).to eq(10.0)
    end

    it "adds shares to existing open position" do
      position = create(:position, portfolio: portfolio, asset: asset, shares: 5.0, avg_cost: 140.0, status: :open)

      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(15.0)
    end
  end

  describe "sell trades" do
    let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 140.0, status: :open) }

    let(:sell_params) do
      {
        asset_symbol: "AAPL",
        side: "sell",
        shares: 5.0,
        price_per_share: 160.0
      }
    end

    it "reduces shares on existing position" do
      result = described_class.call(user: user, params: sell_params)

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(5.0)
      expect(position.status).to eq("open")
    end

    it "closes position when selling all shares" do
      result = described_class.call(user: user, params: sell_params.merge(shares: 10.0))

      expect(result).to be_success
      position.reload
      expect(position.status).to eq("closed")
      expect(position.shares).to eq(0.0)
      expect(position.closed_at).to be_present
    end

    it "fails when no open position exists" do
      position.update!(status: :closed, shares: 0)

      result = described_class.call(user: user, params: sell_params)

      expect(result).to be_failure
      expect(result.failure).to eq([ :insufficient_shares, "Not enough shares to sell" ])
    end

    it "fails when selling more shares than owned" do
      result = described_class.call(user: user, params: sell_params.merge(shares: 20.0))

      expect(result).to be_failure
      expect(result.failure).to eq([ :insufficient_shares, "Not enough shares to sell" ])
    end
  end

  describe "event publishing" do
    it "publishes TradeExecuted event" do
      handler = class_double(Trading::Handlers::RecalculateAvgCostOnTrade, call: nil).as_stubbed_const
      EventBus.subscribe(Trading::Events::TradeExecuted, handler)

      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_success
      expect(handler).to have_received(:call).with(an_instance_of(Trading::Events::TradeExecuted))
    end
  end

  describe "edge cases" do
    it "uses current time when executed_at not provided" do
      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_success
      expect(result.value!.executed_at).to be_within(5.seconds).of(Time.current)
    end

    it "fails with invalid params" do
      result = described_class.call(user: user, params: { asset_symbol: "", side: "buy", shares: -1.0, price_per_share: 0.0 })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails when user has no portfolio" do
      portfolio.destroy!
      user.reload

      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_failure
      expect(result.failure).to eq([ :not_found, "Portfolio not found" ])
    end
  end
end
