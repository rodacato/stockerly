require "rails_helper"

RSpec.describe Trading::Handlers::RebuildSnapshotsOnBackdatedTrade do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user))
      .tap { |p| p.update!(inception_date: 30.days.ago.to_date) }
  end
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 10) }

  def trade_on(date)
    create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: 100,
                   price_per_share: 10, currency: "MXN", executed_at: date)
  end

  def event_for(trade)
    Trading::Events::TradeExecuted.new(
      trade_id: trade.id, user_id: user.id, position_id: 0, side: "buy", shares: "100"
    )
  end

  it "runs async, off the capture request" do
    expect(described_class.async?).to be(true)
  end

  it "rebuilds from the trade's date when it is backdated" do
    create(:asset_price_history, asset: asset, date: 5.days.ago.to_date, close: 10)
    trade = trade_on(5.days.ago)

    described_class.call(event_for(trade))

    expect(portfolio.snapshots.find_by(date: 5.days.ago.to_date).total_value).to eq(1_000)
  end

  it "does not rebuild for a trade recorded on its own day" do
    trade = trade_on(Time.current)

    expect { described_class.call(event_for(trade)) }.not_to change(PortfolioSnapshot, :count)
  end

  it "rebuilds when a backdated trade is discarded, reading the portfolio without it" do
    create(:asset_price_history, asset: asset, date: 5.days.ago.to_date, close: 10)
    trade = trade_on(5.days.ago)
    described_class.call(event_for(trade))
    expect(portfolio.snapshots.find_by(date: 5.days.ago.to_date).total_value).to eq(1_000)

    trade.discard!
    described_class.call({ trade_id: trade.id })

    expect(portfolio.snapshots.find_by(date: 5.days.ago.to_date).total_value).to eq(0)
  end

  it "survives a trade that no longer exists" do
    expect { described_class.call({ trade_id: 0 }) }.not_to raise_error
  end

  it "accepts the serialized hash form the async path delivers" do
    create(:asset_price_history, asset: asset, date: 4.days.ago.to_date, close: 10)
    trade = trade_on(4.days.ago)

    described_class.call({ trade_id: trade.id })

    expect(portfolio.snapshots.find_by(date: 4.days.ago.to_date).total_value).to eq(1_000)
  end
end
