require "rails_helper"

RSpec.describe "The asset detail's verdict card", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 184, sync_status: :active) }

  before { login_as(user) }

  def observe(type, at: Time.current)
    TechnicalObservation.create!(asset: asset, observation_type: type, observed_at: at,
                                 indicator_snapshot: { rsi: 72 })
  end

  # ADR-014: the phrase is selected from the catalogue, and which one depends on
  # whether the reader holds the asset — a fact the instance owns.
  it "speaks to a holder about taking partial profits" do
    create(:position, portfolio: portfolio, asset: asset, shares: 40, avg_cost: 120, status: :open)
    observe("rsi_overbought_entered")

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.estado.stretched.holding"))
    expect(response.body).not_to include(I18n.t("market.estado.stretched.watching"))
  end

  it "speaks to a watcher about not entering" do
    observe("rsi_overbought_entered")

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.estado.stretched.watching"))
  end

  # Renata's condition in the ADR: the phrase never stands alone.
  it "keeps the reading that produced the phrase on screen" do
    observe("rsi_overbought_entered")

    get market_asset_path(asset.symbol)

    expect(response.body).to include("RSI 72")
    expect(response.body).to include("entró en zona de sobrecompra")
  end

  # Lucía's condition: prose hides staleness better than a number.
  it "dates a state derived from an older observation" do
    observe("rsi_overbought_entered", at: 3.days.ago)

    get market_asset_path(asset.symbol)

    expect(response.body).to include("hace 3 días")
  end

  it "says there are no extremes rather than staying silent" do
    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.estado.neutral.watching"))
  end

  it "returns to neutral once the extreme is left" do
    observe("rsi_overbought_entered", at: 3.days.ago)
    observe("rsi_overbought_exited", at: 1.hour.ago)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.estado.neutral.watching"))
    expect(response.body).not_to include(I18n.t("market.estado.stretched.watching"))
  end

  # D2, and the reason it was decided: the widget shipped the symbol being
  # viewed to a third party on every page load.
  describe "the third-party chart widget" do
    it "is gone, script and all" do
      get market_asset_path(asset.symbol)

      expect(response.body).not_to include("tradingview")
      expect(response.body).not_to include("s3.tradingview.com")
    end

    # Functional references only — a comment explaining why the widget was
    # removed is the opposite of a regression.
    it "leaves no way to load it anywhere in the app" do
      wiring = /data-controller="tradingview"|tradingview_symbol|s3\.tradingview\.com|TradingviewController/
      sources = Dir.glob("app/**/*.{rb,erb,js}")
      offenders = sources.select { |f| File.read(f).match?(wiring) }

      expect(offenders).to be_empty, "still wired in: #{offenders.join(", ")}"
    end
  end
end
