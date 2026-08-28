require "rails_helper"

RSpec.describe Trading::Domain::RealizedGain do
  let(:user) { create(:user, preferred_currency: "MXN") }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, symbol: "AAPL", currency: "USD") }
  let(:position) { create(:position, portfolio: portfolio, asset: asset, status: :closed) }

  def trade(side:, shares:, price:, fx:, fee: 0)
    create(:trade, portfolio: portfolio, position: position, asset: asset,
                   side: side, shares: shares, price_per_share: price,
                   fx_rate_at_execution: fx, fee: fee, currency: "USD")
  end

  it "is what the sales brought in minus what the purchases cost" do
    trade(side: :buy,  shares: 10, price: 100, fx: 17)
    trade(side: :sell, shares: 10, price: 120, fx: 18)

    # 10*120*18 = 21,600 in, 10*100*17 = 17,000 out
    expect(described_class.new(position.reload, currency: "MXN").amount).to eq(4_600)
  end

  # The reason fx_rate_at_execution exists: a gain earned at 17 does not become
  # a different number because today's rate is 20.
  it "values each leg at its own rate, not at today's" do
    trade(side: :buy,  shares: 1, price: 100, fx: 17)
    trade(side: :sell, shares: 1, price: 100, fx: 20)

    expect(described_class.new(position.reload, currency: "MXN").amount).to eq(300)
  end

  it "takes fees off the proceeds and adds them to the cost" do
    trade(side: :buy,  shares: 1, price: 100, fx: 10, fee: 5)
    trade(side: :sell, shares: 1, price: 100, fx: 10, fee: 5)

    expect(described_class.new(position.reload, currency: "MXN").amount).to eq(-100)
  end

  it "reports a loss as a negative number rather than an absolute one" do
    trade(side: :buy,  shares: 10, price: 100, fx: 10)
    trade(side: :sell, shares: 10, price: 80,  fx: 10)

    expect(described_class.new(position.reload, currency: "MXN").amount).to eq(-2_000)
  end

  it "needs no rate when the trade is already in the target currency" do
    mxn_asset = create(:asset, symbol: "WALMEX.MX", currency: "MXN")
    mxn_position = create(:position, portfolio: portfolio, asset: mxn_asset, status: :closed)
    create(:trade, portfolio: portfolio, position: mxn_position, asset: mxn_asset,
                   side: :buy, shares: 10, price_per_share: 60, currency: "MXN", fx_rate_at_execution: nil)
    create(:trade, portfolio: portfolio, position: mxn_position, asset: mxn_asset,
                   side: :sell, shares: 10, price_per_share: 70, currency: "MXN", fx_rate_at_execution: nil)

    expect(described_class.new(mxn_position.reload, currency: "MXN").amount).to eq(100)
  end

  # Fail loud: a wrong gain on a money screen is worse than one that says it
  # cannot be computed.
  it "refuses to guess when a leg has no captured rate" do
    trade(side: :buy,  shares: 1, price: 100, fx: nil)
    trade(side: :sell, shares: 1, price: 120, fx: 18)

    expect { described_class.new(position.reload, currency: "MXN").amount }
      .to raise_error(Trading::Domain::MissingFxRate, /fx_rate_at_execution/)
  end

  it "ignores discarded trades" do
    trade(side: :buy,  shares: 10, price: 100, fx: 10)
    trade(side: :sell, shares: 10, price: 110, fx: 10)
    trade(side: :sell, shares: 10, price: 999, fx: 10).update!(discarded_at: Time.current)

    expect(described_class.new(position.reload, currency: "MXN").amount).to eq(1_000)
  end

  it "is zero for a position with no trades rather than raising" do
    expect(described_class.new(position, currency: "MXN").amount).to eq(0)
  end
end
