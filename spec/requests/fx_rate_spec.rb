require "rails_helper"

RSpec.describe "The trade sheet's FX lookup", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:source) { MarketData::Gateways::BanxicoGateway::FIX_SOURCE_ID }

  before { login_as(user) }

  def body_for(date)
    get fx_rate_path, params: { currency: "USD", date: date.to_s }
    JSON.parse(response.body)
  end

  it "answers with the rate for the date asked" do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 4), rate: 17.4948, source: source)

    expect(body_for(Date.new(2026, 5, 4))).to include(
      "rate" => 17.4948, "date" => "2026-05-04", "source" => source
    )
  end

  # The sheet renders "FIX de Banxico del %{date}" from this field, so echoing
  # the date asked rather than the one used made that sentence untrue.
  it "reports the date of the row it actually used, not the one requested" do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 4, 30), rate: 17.4030, source: source)

    expect(body_for(Date.new(2026, 5, 4))).to include("rate" => 17.403, "date" => "2026-04-30")
  end

  it "names the source from the row instead of assuming one" do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 4), rate: 17.4948, source: "manual")

    expect(body_for(Date.new(2026, 5, 4))["source"]).to eq("manual")
  end

  it "returns a null rate and no source when nothing is stored" do
    expect(body_for(Date.new(2026, 5, 4))).to include(
      "rate" => nil, "source" => nil, "date" => "2026-05-04"
    )
  end
end
