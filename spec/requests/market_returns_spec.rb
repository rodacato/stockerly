require "rails_helper"

# The Rendimiento block (#611). D89 deferred it on its trigger; the trigger is
# now documented, and it changed the block's shape: 1D and 1S are not on the
# artboard, and Total came off it because Tu posición already is one.
RSpec.describe "Market Rendimiento block", type: :request do
  let!(:user) { create(:user, email: "rend@example.com", password: "password123", preferred_currency: "USD") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, symbol: "NVDA", currency: "USD") }

  before { login_as(user) }

  def hold_since(days, price_from:, price_to:)
    position = create(:position, portfolio: portfolio, asset: asset, shares: 10,
                                 avg_cost: price_from, status: :open, opened_at: days.days.ago)
    create(:trade, portfolio: portfolio, asset: asset, position: position, side: :buy,
                   shares: 10, price_per_share: price_from, executed_at: days.days.ago)
    days.downto(0) do |d|
      close = price_from + ((price_to - price_from) * (days - d) / days.to_f)
      create(:asset_price_history, asset: asset, date: d.days.ago.to_date,
                                   open: close, high: close, low: close, close: close)
    end
  end

  it "shows what the position made over each window, in money" do
    hold_since(400, price_from: 100, price_to: 140)

    get market_asset_path(asset.symbol)

    expect(response.body).to include("Rendimiento")
    expect(response.body).to include("1 día", "1 sem", "1 mes", "3 meses", "1 año")
  end

  it "does not offer a window older than the position" do
    hold_since(10, price_from: 100, price_to: 110)

    get market_asset_path(asset.symbol)

    expect(response.body).to include("1 día", "1 sem")
    expect(response.body).not_to include("3 meses")
  end

  it "stays away entirely when nothing is held" do
    create(:asset_price_history, asset: asset, date: Date.current, close: 100)

    get market_asset_path(asset.symbol)

    expect(response.body).not_to include("Rendimiento")
  end

  # The bug this block introduced before it was guarded: Portfolio#convert
  # fails loudly on a missing rate — correct, and by design — so an unguarded
  # conversion took the whole asset detail down with it (ADR-0023).
  it "goes absent and says why when the rate is missing, rather than 500ing" do
    user.update!(preferred_currency: "MXN")
    hold_since(400, price_from: 100, price_to: 140)
    FxRate.delete_all
    FxRateHistory.delete_all

    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("comun.sin_tc_titulo"))
  end

  # The header already states the day change as a percentage. The block earns
  # its place by being in money, so the money is what must be there.
  it "leads with pesos, not with the percentage the header already shows" do
    hold_since(400, price_from: 100, price_to: 140)

    get market_asset_path(asset.symbol)

    expect(response.body).to match(/[+−]USD/)
  end
end
