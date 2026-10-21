require "rails_helper"

# D159: lo tuyo goes first, under the price and above the tabs.
RSpec.describe "The asset detail's Lo tuyo card", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
  end

  def hold(asset, shares: 10, avg_cost: 100)
    create(:position, portfolio: portfolio, asset: asset, shares: shares, avg_cost: avg_cost, status: :open)
  end

  it "puts the position, its weight and the cost before the chart and the tabs" do
    hold(asset)

    get market_asset_path(asset.symbol)

    body = response.body
    expect(body).to include("Tu posición · MXN 24,000")
    expect(body).to include("Pesa 100% de tu patrimonio")
    expect(body.index(I18n.t("market.mine.titulo"))).to be < body.index('role="tablist"')
  end

  it "weighs the holding against the whole patrimonio" do
    hold(asset)
    other = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 100)
    hold(other, shares: 240, avg_cost: 90)

    get market_asset_path(asset.symbol)

    expect(response.body).to include("Pesa 50% de tu patrimonio")
  end

  it "states the next earnings date, which Hoy links here to see" do
    create(:earnings_event, asset: asset, report_date: 7.days.from_now.to_date)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.mine.titulo"))
    expect(response.body).to include("en 7 días")
  end

  it "draws no card when there is nothing of yours to put in it" do
    get market_asset_path(asset.symbol)

    expect(response.body).not_to include(I18n.t("market.mine.titulo"))
  end

  it "draws the verdict without a warning or buy tone, even when the state is stretched" do
    create(:technical_observation, :bb_upper_breached, asset: asset, observed_at: 1.hour.ago)

    get market_asset_path(asset.symbol)

    verdict = Capybara.string(response.body).find("section", text: I18n.t(MarketData::Domain::AssetState.label_key(:stretched)))
    expect(verdict[:class]).not_to match(/warning|positive|negative/)
  end

  it "gives the analyst target its source and date and no direction colour" do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", source: "Yahoo Finance", calculated_at: Time.current,
                               metrics: { "analyst_target_price" => "150", "fifty_two_week_low" => "80", "fifty_two_week_high" => "200" })

    get market_asset_path(asset.symbol)

    expect(response.body).to include("Consenso publicado por Yahoo Finance")
    expect(response.body).not_to match(/Diferencia.{0,200}text-(positive|negative)-fg/m)
  end
end
