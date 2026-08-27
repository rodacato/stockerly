require "rails_helper"

RSpec.describe SyncDividendsJob, type: :job do
  let(:gateway) { instance_double(MarketData::Gateways::AlpacaGateway) }
  let(:asset) { create(:asset, :stock) }
  let(:portfolio) { create(:portfolio) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, status: :open) }

  before do
    create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")
    allow(MarketData::Gateways::AlpacaGateway).to receive(:new).and_return(gateway)
  end

  it "syncs dividends for assets with open positions" do
    create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 10,
                   executed_at: Date.new(2026, 3, 1))
    dividend_data = [
      { ex_date: Date.new(2026, 3, 15), pay_date: Date.new(2026, 3, 30),
        amount_per_share: 0.50, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends).with(asset.symbol)
      .and_return(Dry::Monads::Success(dividend_data))

    expect { described_class.perform_now }.to change(Dividend, :count).by(1)
      .and change(DividendPayment, :count).by(1)
  end

  it "skips assets when the chain has nothing to offer" do
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Failure([ :not_found, "no dividends" ]))
    allow(PythonRunner).to receive(:call)
      .and_return(Dry::Monads::Failure([ :not_found, "no dividends" ]))

    expect { described_class.perform_now }.not_to change(Dividend, :count)
  end

  it "publishes DividendsSynced event" do
    dividend_data = [
      { ex_date: Date.new(2026, 4, 1), pay_date: nil,
        amount_per_share: 1.25, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Success(dividend_data))

    handler = class_double(MarketData::Handlers::LogDividendsSync, call: nil)
    EventBus.subscribe(MarketData::Events::DividendsSynced, handler)

    described_class.perform_now

    expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::DividendsSynced))
  end

  # Entitlement is settled on the ex-date. The job used to read the open
  # position, which is the holding as it stands now — wrong in both directions
  # (#305), and these are the two sides of it.
  describe "who is entitled" do
    # Dates are relative: the job only asks about assets closed inside its
    # 90-day window, so fixed dates would pass today and rot by next year.
    let(:ex_date) { 30.days.ago.to_date }
    let(:dividend_data) do
      [ { ex_date: ex_date, pay_date: ex_date + 15.days,
          amount_per_share: 0.50, currency: "USD" } ]
    end

    before do
      allow(gateway).to receive(:fetch_dividends).and_return(Dry::Monads::Success(dividend_data))
    end

    it "pays nothing for shares bought after the ex-date" do
      create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 10,
                     executed_at: ex_date + 5.days)

      expect { described_class.perform_now }.not_to change(DividendPayment, :count)
    end

    it "pays a position that held through the ex-date and has since closed" do
      create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 10,
                     executed_at: ex_date - 10.days)
      create(:trade, portfolio: portfolio, asset: asset, side: :sell, shares: 10,
                     executed_at: ex_date + 5.days)
      position.update!(status: :closed, shares: 0, closed_at: ex_date + 5.days)

      expect { described_class.perform_now }.to change(DividendPayment, :count).by(1)
      expect(DividendPayment.last.shares_held).to eq(10)
    end

    it "counts only the shares held on the ex-date, not the ones added after" do
      create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 10,
                     executed_at: ex_date - 10.days)
      create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 40,
                     executed_at: ex_date + 5.days)

      described_class.perform_now

      expect(DividendPayment.last.shares_held).to eq(10)
      expect(DividendPayment.last.total_amount).to eq(5.00)
    end
  end

  it "does not duplicate existing dividends" do
    create(:dividend, asset: asset, ex_date: Date.new(2026, 5, 1), amount_per_share: 0.30)

    dividend_data = [
      { ex_date: Date.new(2026, 5, 1), pay_date: nil,
        amount_per_share: 0.30, currency: "USD" }
    ]
    allow(gateway).to receive(:fetch_dividends)
      .and_return(Dry::Monads::Success(dividend_data))

    expect { described_class.perform_now }.not_to change(Dividend, :count)
  end
end
