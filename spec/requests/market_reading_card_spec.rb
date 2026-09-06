require "rails_helper"

# D114: Señales, Niveles and Observaciones used to be three cards answering the
# same question, so the screen offered three glances at one question. They are
# now three sections of one card, and the order inside it follows what the
# measurement showed rather than habit.
RSpec.describe "Market Asset Detail — la tarjeta de lectura", type: :request do
  let!(:user) { create(:user, email: "reading@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }

  before { login_as(user) }

  def full_reading
    create(:technical_reading, asset: asset,
           readings: { "close" => 150.0, "rsi" => 72.0, "sma_50" => 145.0, "sma_200" => 130.0,
                       "bb_upper" => 160.0, "bb_lower" => 136.0, "atr" => 4.0 })
  end

  # The three headings living under one card is the whole decision; three
  # <section> wrappers would be the state D114 replaced.
  it "draws the three sections inside a single card" do
    full_reading
    create(:technical_observation, asset: asset, observation_type: "bb_upper_breached", observed_at: 1.hour.ago)

    get market_asset_path(asset.symbol)
    card = response.body[/#{Regexp.escape(I18n.t("market.reading.titulo"))}.*?<\/section>/m].to_s

    expect(card).to include(I18n.t("market.layers.seccion"))
    expect(card).to include(I18n.t("market.recent_observations.seccion"))
    expect(card).to include(I18n.t("market.signals.rsi.overbought"))
  end

  # Measured over 94,282 days, the MA200 side is the only one of these that
  # moves whether an entry held; the RSI moves whether it fills. An order that
  # slipped back would put the weaker evidence first without anyone noticing.
  it "puts the moving averages above the RSI" do
    full_reading

    get market_asset_path(asset.symbol)
    ma = response.body.index(I18n.t("market.signals.moving_average.above_both"))
    rsi = response.body.index(I18n.t("market.signals.rsi.overbought"))

    expect(ma).to be_present
    expect(rsi).to be_present
    expect(ma).to be < rsi
  end

  it "carries the fill rate as a constant beside the levels" do
    full_reading

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.layers.evidencia"))
  end

  # The card answers a question the reader still has when one source is empty,
  # so it draws on any one of the three rather than on all of them.
  it "draws for an asset that has levels but no observations" do
    full_reading

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.reading.titulo"))
    expect(response.body).not_to include(I18n.t("market.recent_observations.seccion"))
  end

  it "is absent entirely when the asset has nothing computed" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("market.reading.titulo"))
  end
end
