require "rails_helper"

RSpec.describe "The asset detail header", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) do
    create(:asset, :stock, symbol: "NVDA", name: "Nvidia", currency: "USD",
                           current_price: 184, change_percent_24h: -2.1, sync_status: :active)
  end

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 20.0)
  end

  # The MXN-first point: a USD quote means little until you see it in pesos.
  it "shows the price in the reader's own currency too" do
    get market_asset_path(asset.symbol)

    expect(response.body).to include("184.00")
    expect(response.body).to include("MXN 3,680")
  end

  it "omits the approximation for an asset that already quotes in it" do
    mxn = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70, sync_status: :active)

    get market_asset_path(mxn.symbol)

    expect(response.body).to include("70.00")
    expect(response.body).not_to include("≈")
  end

  # An approximation invented from a missing rate is worse than its absence.
  it "omits it rather than inventing a rate" do
    FxRate.delete_all

    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("≈")
  end

  it "drops the three-level breadcrumb for a single back link" do
    get market_asset_path(asset.symbol)

    expect(response.body).not_to include("Mercados")
    expect(response.body).to include(%(href="#{assets_path}"))
  end

  it "keeps the bookmark, which is the one action the artboard has" do
    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.header.agregar_watchlist"))
    expect(response.body).not_to include("Alerta de precio")
  end

  # The header's capture button moved to the foot of Mi posición. Exactly one,
  # wherever it is: a screenshot caught two the first time round.
  it "offers exactly one way to record a movement when you hold the asset" do
    position = create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy, shares: 10,
                   price_per_share: 100, currency: "USD", fx_rate_at_execution: 17.0, executed_at: 30.days.ago)

    get market_asset_path(asset.symbol)

    # Counting the link, not the string: the sheet partial also uses the same
    # phrase as the dialog's accessible name.
    expect(response.body.scan(%(href="#{new_trade_path}")).size).to eq(1)
  end

  it "offers none from the header alone when you do not hold it" do
    get market_asset_path(asset.symbol)

    expect(response.body).not_to include(%(href="#{new_trade_path}"))
  end

  # Where a number came from is not decoration on a screen whose job is being
  # checkable, so the provenance line stays even though the artboard drops it.
  it "keeps the data-source caption" do
    get market_asset_path(asset.symbol)

    expect(response.body).to include("Fuente:")
  end
end
