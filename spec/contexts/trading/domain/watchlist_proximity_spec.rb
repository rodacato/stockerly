require "rails_helper"

RSpec.describe Trading::Domain::WatchlistProximity do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, :stock, symbol: "AAPL", current_price: 100) }

  before { create(:watchlist_item, user: user, asset: asset) }

  it "measures the distance to the nearest active price threshold, in percent" do
    create(:alert_rule, user: user, asset_symbol: "AAPL", threshold_value: 105)
    create(:alert_rule, user: user, asset_symbol: "AAPL", threshold_value: 130)

    expect(described_class.gaps(user)["AAPL"]).to be_within(0.001).of(5.0)
  end

  it "ignores paused rules and assets without a threshold" do
    create(:alert_rule, :paused, user: user, asset_symbol: "AAPL", threshold_value: 101)

    expect(described_class.gaps(user)).to eq({})
  end

  it "has no distance for an asset without a price" do
    asset.update!(current_price: nil)
    create(:alert_rule, user: user, asset_symbol: "AAPL", threshold_value: 105)

    expect(described_class.gaps(user)).to eq({})
  end
end
