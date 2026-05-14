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

  describe "currency and fx_rate capture (#42 / S2-B)" do
    let(:mx_user) { create(:user, preferred_currency: "MXN") }
    let!(:mx_portfolio) { create(:portfolio, user: mx_user) }

    context "when trade currency matches user preferred currency" do
      let!(:mxn_asset) { create(:asset, :mexican, symbol: "WALMEX.MX") }

      it "stores fx_rate_at_execution = 1.0 without any gateway call" do
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(
          user: mx_user,
          params: buy_params.merge(asset_symbol: "WALMEX.MX")
        )

        expect(result).to be_success
        trade = result.value!
        expect(trade.currency).to eq("MXN")
        expect(trade.fx_rate_at_execution).to eq(1.0)
      end

      it "derives currency from the asset, ignoring missing param" do
        result = described_class.call(
          user: mx_user,
          params: buy_params.merge(asset_symbol: "WALMEX.MX")
        )

        expect(result.value!.currency).to eq("MXN")
      end
    end

    context "when trade currency differs and FxRate exists in DB" do
      let!(:fx_rate) { create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5) }

      it "uses the latest FxRate without calling the gateway" do
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(user: mx_user, params: buy_params)

        expect(result).to be_success
        expect(result.value!.fx_rate_at_execution).to eq(17.5)
      end
    end

    context "when explicit fx_rate_at_execution is provided" do
      let!(:fx_rate) { create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5) }

      it "honors the manual override even when DB has a different rate" do
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(
          user: mx_user,
          params: buy_params.merge(fx_rate_at_execution: 18.42)
        )

        expect(result).to be_success
        expect(result.value!.fx_rate_at_execution).to eq(18.42)
      end
    end

    context "when no FxRate exists and gateway refresh succeeds" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway) }

      it "refreshes via the gateway and uses the new rate" do
        allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:refresh_rates) do
          FxRate.create!(base_currency: "USD", quote_currency: "MXN", rate: 17.25, fetched_at: Time.current)
        end

        result = described_class.call(user: mx_user, params: buy_params)

        expect(result).to be_success
        expect(result.value!.fx_rate_at_execution).to eq(17.25)
        expect(gateway).to have_received(:refresh_rates).with(base: "USD", targets: [ "MXN" ])
      end
    end

    context "when only an inverse rate exists" do
      let!(:usd_user) { create(:user, preferred_currency: "USD") }
      let!(:usd_portfolio) { create(:portfolio, user: usd_user) }
      let!(:mxn_asset) { create(:asset, :mexican, symbol: "WALMEX.MX") }
      let!(:inverse_rate) { create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5) }
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil) }

      before { allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway) }

      it "inverts the rate when forward direction is missing" do
        result = described_class.call(
          user: usd_user,
          params: buy_params.merge(asset_symbol: "WALMEX.MX")
        )

        expect(result).to be_success
        expect(result.value!.fx_rate_at_execution).to be_within(0.0001).of(1.0 / 17.5)
      end
    end

    context "when no rate is available anywhere" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil) }

      before { allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway) }

      it "fails with :fx_rate_unavailable" do
        result = described_class.call(user: mx_user, params: buy_params)

        expect(result).to be_failure
        expect(result.failure.first).to eq(:fx_rate_unavailable)
        expect(result.failure[1]).to include("USD -> MXN")
      end

      it "does not persist a partial trade" do
        expect { described_class.call(user: mx_user, params: buy_params) }
          .not_to change(Trade, :count)
      end
    end

    context "when the gateway raises an error" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway) }

      before do
        allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:refresh_rates).and_raise(StandardError, "API down")
      end

      it "falls back to inverse rate if available" do
        create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: 0.06)

        # Inverse is "MXN -> USD". We want "USD -> MXN" which is 1/0.06 ≈ 16.66.
        # But our user is mx_user (preferred MXN) buying USD asset, so we lookup USD -> MXN.
        # The seeded row is MXN -> USD, which is the INVERSE of what we want.
        result = described_class.call(user: mx_user, params: buy_params)

        expect(result).to be_success
        expect(result.value!.fx_rate_at_execution).to be_within(0.01).of(1.0 / 0.06)
      end

      it "fails cleanly when no fallback exists" do
        result = described_class.call(user: mx_user, params: buy_params)

        expect(result).to be_failure
        expect(result.failure.first).to eq(:fx_rate_unavailable)
      end
    end
  end

  describe "contract changes for currency / fx_rate (#42)" do
    it "rejects unsupported currency values" do
      result = described_class.call(user: user, params: buy_params.merge(currency: "EUR"))

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "rejects non-positive fx_rate_at_execution" do
      result = described_class.call(user: user, params: buy_params.merge(fx_rate_at_execution: 0))

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
