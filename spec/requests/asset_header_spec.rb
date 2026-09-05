require "rails_helper"

RSpec.describe "The asset detail header", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) do
    create(:asset, :stock, symbol: "NVDA", name: "Nvidia", currency: "USD",
                           current_price: 184, sync_status: :active)
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

  # The header's capture button moved to the foot of Mi posición, and both tabs
  # live in the same document. What must be unique is the FRAME, not the link:
  # components/_sheet_dialog mounts a turbo_frame_tag named trade_sheet, so a
  # second mount would give two frames one name — Turbo fills the first, and the
  # button on the other tab opens an empty drawer. A screenshot caught that.
  it "mounts the trade sheet exactly once, however many doors reach it" do
    position = create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy, shares: 10,
                   price_per_share: 100, currency: "USD", fx_rate_at_execution: 17.0, executed_at: 30.days.ago)

    get market_asset_path(asset.symbol)

    expect(response.body.scan(%(id="trade_sheet")).size).to eq(1)
  end

  it "reaches it from both tabs, since switching tabs must not lose the action" do
    position = create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)
    create(:trade, portfolio: portfolio, position: position, asset: asset, side: :buy, shares: 10,
                   price_per_share: 100, currency: "USD", fx_rate_at_execution: 17.0, executed_at: 30.days.ago)

    get market_asset_path(asset.symbol)

    expect(response.body.scan(%(href="#{new_trade_path(symbol: asset.symbol)}")).size).to eq(2)
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
