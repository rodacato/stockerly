require "rails_helper"

# ADR-0023. Before it, three of these paths had no guard at all and answered a
# missing rate with a 500, while two others answered it with a zero.
RSpec.describe Trading::UseCases::AssembleConsolidado do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user)).tap { |p| p.update!(inception_date: 2.years.ago.to_date) }
  end

  let(:usd_asset) { create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 200) }

  def data = described_class.call(user: user.reload)

  before do
    portfolio.snapshots.create!(date: 30.days.ago.to_date, currency: "USD", total_value: 1_000)
    portfolio.snapshots.create!(date: 2.days.ago.to_date, currency: "USD", total_value: 1_200)
    create(:trade, portfolio: portfolio, asset: usd_asset, side: :buy, shares: 5,
                   price_per_share: 200, currency: "USD", executed_at: 40.days.ago)
  end

  it "keeps the page instead of raising through it" do
    expect { data }.not_to raise_error
  end

  it "says why the figures are missing" do
    expect(data[:fx_unavailable]).to be(true)
  end

  it "absents the series rather than drawing days worth nothing" do
    expect(data[:series]).to eq([])
  end

  it "absents the comparison rather than flattering it" do
    expect(data[:vs_hold]).to be_nil
  end

  it "still answers what does not depend on a rate" do
    expect(data[:currency]).to eq("MXN")
    expect(data[:period]).to eq("1A")
  end

  it "stops saying so once the rate exists" do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.1)
    record_fix_series(from: 60.days.ago.to_date, to: Date.current, rate: 17.1)

    expect(data[:fx_unavailable]).to be(false)
  end

  # #537: today's rate no longer answers for a snapshot dated a month back, so
  # the series each figure needs has to be there for the banner to clear.
  it "keeps saying so when only today's rate exists" do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.1)

    expect(data[:fx_unavailable]).to be(true)
  end

  def record_fix_series(from:, to:, rate:)
    FxRateHistory.record_all(
      (from..to).map do |date|
        { base_currency: "USD", quote_currency: "MXN", rate_date: date, rate: rate, source: "banxico_fix" }
      end
    )
  end
end
