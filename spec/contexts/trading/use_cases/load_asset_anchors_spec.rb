require "rails_helper"

RSpec.describe Trading::UseCases::LoadAssetAnchors do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 150.0) }

  it "returns no anchors when nothing is held and no rule is set" do
    result = described_class.call(asset: asset, position_data: nil, rules: [])

    expect(result[:cost]).to be_nil
    expect(result[:threshold]).to be_nil
    expect(result[:other_rules]).to eq([])
  end

  it "anchors the price against what the position cost" do
    portfolio = create(:portfolio, user: user)
    position = create(:position, portfolio: portfolio, asset: asset, avg_cost: 120.0)

    result = described_class.call(asset: asset, position_data: { position: position }, rules: [])

    expect(result[:cost]).to be_present
  end

  it "picks the price-threshold rule and leaves the rest for the list" do
    price_rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 160.0)
    other = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :day_change_percent, threshold_value: 3.0)

    result = described_class.call(asset: asset, position_data: nil, rules: [ other, price_rule ])

    expect(result[:threshold_rule]).to eq(price_rule)
    expect(result[:threshold]).to be_present
    expect(result[:other_rules]).to eq([ other ])
  end

  # day_change_percent stores a percentage and rsi_* an index level, so a quote
  # compared against either would be nonsense (AlertRule::PRICE_THRESHOLD_CONDITIONS).
  it "does not anchor against a rule whose threshold is not a price" do
    rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :rsi_overbought, threshold_value: 70.0)

    result = described_class.call(asset: asset, position_data: nil, rules: [ rule ])

    expect(result[:threshold]).to be_nil
    expect(result[:other_rules]).to eq([ rule ])
  end

  it "ignores a paused rule" do
    rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above,
                  threshold_value: 160.0, status: :paused)

    result = described_class.call(asset: asset, position_data: nil, rules: [ rule ])

    expect(result[:threshold_rule]).to be_nil
  end
end
