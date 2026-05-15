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

    it "leaves maturity_date nil for stock positions even when supplied" do
      result = described_class.call(
        user: user,
        params: buy_params.merge(maturity_date: 28.days.from_now.to_date.iso8601)
      )
      expect(result).to be_success
      expect(result.value!.position.maturity_date).to be_nil
    end

    it "adds shares to existing open position" do
      position = create(:position, portfolio: portfolio, asset: asset, shares: 5.0, avg_cost: 140.0, status: :open)

      result = described_class.call(user: user, params: buy_params)

      expect(result).to be_success
      position.reload
      expect(position.shares).to eq(15.0)
    end
  end

  describe "fixed-income trades (#29 JTBD #3)" do
    # CETES are MXN-only; pin the user to MXN so this spec exercises the
    # maturity_date flow rather than the FX-resolution branch (covered in
    # the currency/fx_rate describe block below and in fx_rate_resolver_spec).
    let(:user) { create(:user, preferred_currency: "MXN") }
    let!(:portfolio) { create(:portfolio, user: user) }
    let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D") }
    let(:maturity) { 28.days.from_now.to_date }

    let(:cetes_buy_params) do
      {
        asset_symbol: "CETES_28D",
        side: "buy",
        shares: 100.0,
        price_per_share: 9.85,
        maturity_date: maturity.iso8601
      }
    end

    it "persists maturity_date onto the new position" do
      result = described_class.call(user: user, params: cetes_buy_params)
      expect(result).to be_success
      expect(result.value!.position.maturity_date).to eq(maturity)
    end

    it "creates a NEW position on reinvestment (lot-separation, #29 HIGH)" do
      # CETES rolls — each weekly auction is a new lot with its own
      # maturity_date. A second buy of CETES_28D must NOT merge into the
      # earlier lot, otherwise the new maturity is silently dropped (the
      # exact bug Gemini flagged on PR #61 round 1).
      earlier_maturity = 14.days.from_now.to_date
      later_maturity = 91.days.from_now.to_date

      earlier_position = create(
        :position,
        portfolio: portfolio,
        asset: cetes,
        shares: 50.0,
        avg_cost: 9.85,
        maturity_date: earlier_maturity
      )

      result = described_class.call(
        user: user,
        params: cetes_buy_params.merge(maturity_date: later_maturity.iso8601)
      )

      expect(result).to be_success
      new_position = result.value!.position

      # New Position with its own maturity
      expect(new_position).not_to eq(earlier_position)
      expect(new_position.maturity_date).to eq(later_maturity)
      expect(new_position.shares).to eq(100.0)

      # The earlier position is left intact — its maturity_date and share
      # count are not touched by the new trade.
      earlier_position.reload
      expect(earlier_position.maturity_date).to eq(earlier_maturity)
      expect(earlier_position.shares).to eq(50.0)
    end

    it "still merges non-fixed-income trades into existing positions (regression guard)" do
      # Stocks/crypto/etfs continue to merge as before — only fixed_income
      # breaks the merge default.
      stock = create(:asset, :stock, symbol: "MSFT")
      stock_position = create(:position, portfolio: portfolio, asset: stock, shares: 5.0, avg_cost: 100.0)

      result = described_class.call(
        user: user,
        params: {
          asset_symbol: "MSFT",
          side: "buy",
          shares: 3.0,
          price_per_share: 110.0,
          fx_rate_at_execution: 17.5
        }
      )

      expect(result).to be_success
      expect(result.value!.position).to eq(stock_position)
      expect(stock_position.reload.shares).to eq(8.0)
    end

    it "rejects the trade when maturity_date is missing" do
      result = described_class.call(user: user, params: cetes_buy_params.except(:maturity_date))
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
      expect(result.failure[1][:maturity_date]).to include("required for fixed-income assets")
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

  describe "currency and fx_rate capture — integration with FxRateResolver (#42)" do
    # Resolution-branch coverage lives in spec/contexts/trading/domain/fx_rate_resolver_spec.rb.
    # These specs cover what the use case alone is responsible for: deriving currency
    # from the asset, propagating override from params, persisting the resolved rate,
    # and ensuring no partial trade is created when resolution fails.
    let(:mx_user) { create(:user, preferred_currency: "MXN") }
    let!(:mx_portfolio) { create(:portfolio, user: mx_user) }

    it "derives currency from the asset and persists fx_rate when currencies match" do
      create(:asset, :mexican, symbol: "WALMEX.MX")

      result = described_class.call(
        user: mx_user,
        params: buy_params.merge(asset_symbol: "WALMEX.MX")
      )

      expect(result).to be_success
      trade = result.value!
      expect(trade.currency).to eq("MXN")
      expect(trade.fx_rate_at_execution).to eq(BigDecimal(1))
    end

    it "passes through the explicit override from params" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

      result = described_class.call(
        user: mx_user,
        params: buy_params.merge(fx_rate_at_execution: 18.42)
      )

      expect(result).to be_success
      expect(result.value!.fx_rate_at_execution).to eq(BigDecimal("18.42"))
    end

    it "persists the rate resolved by FxRateResolver against the DB" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)

      result = described_class.call(user: mx_user, params: buy_params)

      expect(result).to be_success
      expect(result.value!.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end

    it "fails and does not persist a trade when the resolver returns :fx_rate_unavailable" do
      gateway = instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)

      expect {
        result = described_class.call(user: mx_user, params: buy_params)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:fx_rate_unavailable)
      }.not_to change(Trade, :count)
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
