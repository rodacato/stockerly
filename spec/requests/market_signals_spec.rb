require "rails_helper"

# CKP-3 / #306: the Señales block on the asset detail. Catalogue behaviour is
# specced in spec/contexts/market_data/domain/indicator_signals_spec.rb.
RSpec.describe "Market Asset Detail — Señales", type: :request do
  let!(:user) { create(:user, email: "signals@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }

  # short_date_es formats the stale badge; the spec asserts the string the
  # reader actually sees rather than re-deriving the format. Through the view
  # context, because the helper localizes the date the way a view does.
  let(:formatter) { ApplicationController.helpers }

  before { login_as(user) }

  it "renders a reading as a phrase from the catalogue" do
    create(:technical_reading, asset: asset,
           readings: { "close" => 150.0, "rsi" => 72.0, "sma_50" => 145.0, "sma_200" => 130.0,
                       "bb_upper" => 160.0, "bb_lower" => 136.0 })

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.signals.titulo"))
    expect(response.body).to include(I18n.t("market.signals.rsi.overbought"))
    expect(response.body).to include(I18n.t("market.signals.moving_average.above_both"))
    expect(response.body).to include(I18n.t("market.signals.bollinger.inside"))
  end

  it "omits the block when nothing has been computed for the asset" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("market.signals.titulo"))
  end

  # A phrase in the present tense over an old reading is worse than a stale
  # number, because prose does not look dated (ADR-014, C1 Lucía).
  it "dates a reading that is not from today" do
    create(:technical_reading, asset: asset, calculated_at: 3.days.ago)

    get market_asset_path(asset.symbol)

    expected = I18n.t("market.signals.desactualizado",
                      fecha: formatter.short_date_es(3.days.ago.to_date))
    expect(response.body).to include(expected)
  end

  it "does not date a reading taken today" do
    create(:technical_reading, asset: asset, calculated_at: Time.current)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.signals.titulo"))
    expect(response.body).not_to match(/Lectura del/)
  end
end
