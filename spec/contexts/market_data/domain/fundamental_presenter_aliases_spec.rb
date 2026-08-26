require "rails_helper"

# The gateways and the statement calculator name the same quantity differently.
# Before the alias map, six of the ten Resumen cards rendered "—" on data that
# had arrived and was sitting in the metrics hash under another name.
RSpec.describe MarketData::Domain::FundamentalPresenter, "metric aliasing" do
  let(:asset) { build(:asset, :stock, symbol: "PROBE", current_price: 100) }

  def presenter_for(metrics)
    described_class.new(asset: asset, fundamental: build(:asset_fundamental, metrics: metrics))
  end

  # Exactly the keys AlphaVantageGateway and FmpGateway persist.
  {
    roe:              "return_on_equity",
    roa:              "return_on_assets",
    net_margin:       "profit_margin",
    ev_ebitda:        "ev_to_ebitda",
    revenue_growth:   "quarterly_revenue_growth",
    eps_growth:       "quarterly_earnings_growth",
    total_volume_24h: "total_volume"
  }.each do |canonical, gateway_key|
    it "resolves #{canonical} from the gateway's #{gateway_key}" do
      presenter = presenter_for(gateway_key => "0.42")

      expect(presenter.metric(canonical)).to eq("0.42")
    end
  end

  it "resolves roe from the statement calculator's roe_calculated" do
    expect(presenter_for("roe_calculated" => "1.57").metric(:roe)).to eq("1.57")
  end

  it "prefers the canonical key over an alias when both are present" do
    presenter = presenter_for("net_margin" => "0.30", "profit_margin" => "0.10")

    expect(presenter.metric(:net_margin)).to eq("0.30")
  end

  it "returns nil for a metric no producer writes, rather than an alias's value" do
    expect(presenter_for("profit_margin" => "0.25").metric(:payout_ratio)).to be_nil
  end

  it "does not invent a value when the hash is empty" do
    expect(presenter_for({}).metric(:roe)).to be_nil
  end
end
