require "rails_helper"

# The volatility-layer block on the asset detail. The arithmetic is specced in
# spec/contexts/market_data/domain/volatility_layers_spec.rb; this is about what
# reaches the reader.
RSpec.describe "Market Asset Detail — niveles por volatilidad", type: :request do
  let!(:user) { create(:user, email: "layers@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 100.0, currency: "USD") }

  before { login_as(user) }

  def reading_with_atr(atr)
    create(:technical_reading, asset: asset,
           readings: { "close" => 100.0, "rsi" => 55.0, "atr" => atr })
  end

  it "prices the layers off the asset's own daily range" do
    reading_with_atr(4.0)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.layers.titulo"))
    expect(response.body).to include("96.00", "92.00", "88.00")
  end

  # DoD: a level must say which reading produced it. A price with no ATR and no
  # date behind it is a number the reader cannot check.
  it "names the ATR and the date the levels came from" do
    reading = reading_with_atr(4.0)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(
      I18n.t("market.layers.procedencia",
             atr: "4.00",
             fecha: ApplicationController.helpers.short_date_es(reading.calculated_at.to_date))
    )
  end

  it "omits the block when the reading carries no ATR" do
    create(:technical_reading, asset: asset, readings: { "close" => 100.0, "rsi" => 55.0 })

    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("market.layers.titulo"))
  end

  # An exit level for something you do not hold is a plan for a position that
  # does not exist. The entry side still renders: a watched asset is exactly
  # what entry levels are for.
  describe "the trailing exit" do
    before do
      reading_with_atr(4.0)
      (1..25).each do |i|
        create(:asset_price_history, asset: asset, date: i.days.ago.to_date,
                                     high: 120.0, low: 90.0, close: 100.0)
      end
    end

    it "is absent for an asset that is only watched" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.layers.titulo"))
      expect(response.body).not_to include(I18n.t("market.layers.etiquetas.salida"))
    end

    it "trails the recent high once the asset is held" do
      portfolio = create(:portfolio, user: user)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 90.0)

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.layers.etiquetas.salida"))
      expect(response.body).to include("108.00")
    end
  end
end
