require "rails_helper"

RSpec.describe "Panorama", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  def mxn_asset(**attrs) = create(:asset, :stock, currency: "MXN", **attrs)

  describe "GET /dashboard" do
    it "renders the four blocks" do
      asset = with_day_change(mxn_asset(symbol: "WALMEX", current_price: 70), 1.5)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("PATRIMONIO · MXN")
      expect(response.body).to include(I18n.t("dashboard.show.radar_titulo"))
      expect(response.body).to include(I18n.t("dashboard.show.senales_titulo"))
      expect(response.body).to include("WALMEX")
    end

    it "declares MXN once on the strip and drops the symbol from the figure" do
      asset = with_day_change(mxn_asset(symbol: "AMXL", current_price: 15), 1.0)
      create(:position, portfolio: portfolio, asset: asset, shares: 1_000, avg_cost: 12, status: :open)

      get dashboard_path

      expect(response.body).to include("PATRIMONIO · MXN")
      expect(response.body).to match(/>\s*15,000\s*</)
    end

    it "carries an h1 for the screen at each breakpoint" do
      get dashboard_path

      expect(response.body.scan(/<h1[\s>]/).size).to eq(2)
      expect(response.body).to include(I18n.t("dashboard.show.titulo"))
    end
  end

  # The bug that made this slice necessary: one USD position, MXN preferred,
  # no fx_rates row — the product's central case on a fresh instance.
  describe "when the FX rate for a held currency is missing" do
    before do
      asset = with_day_change(create(:asset, :stock, symbol: "AAPL", currency: "USD",
                                                    current_price: 100), 2.0)
      create(:position, portfolio: portfolio, asset: asset, shares: 5, avg_cost: 80, status: :open)
    end

    it "renders instead of raising" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
    end

    it "says it cannot consolidate rather than inventing a rate" do
      get dashboard_path

      expect(response.body).to include(I18n.t("comun.sin_tc_titulo"))
      expect(response.body).not_to include("PATRIMONIO · MXN")
    end

    it "still shows the radar, because only the consolidation is impossible" do
      get dashboard_path

      expect(response.body).to include("AAPL")
      expect(response.body).to include("USD 500")
    end
  end

  describe "movimientos de interés" do
    let(:asset) { mxn_asset(symbol: "NVDA") }

    before { create(:watchlist_item, user: user, asset: asset) }

    def observe(type, at: Time.current)
      TechnicalObservation.create!(asset: asset, observation_type: type, observed_at: at,
                                   indicator_snapshot: { rsi: 31 })
    end

    # ADR-013: the verb is allowed, and only over a persisted observation.
    it "shows the verb, the phrase that produced it and the indicator" do
      observe("rsi_oversold_entered")

      get dashboard_path

      expect(response.body).to include(I18n.t("comun.accion.buy"))
      expect(response.body).to include("entró en zona de sobreventa")
      expect(response.body).to include("RSI 31")
    end

    it "shows no verb for an observation type that carries none" do
      observe("rsi_oversold_exited")

      get dashboard_path

      expect(response.body).not_to include(I18n.t("comun.accion.buy"))
      expect(response.body).to include(I18n.t("dashboard.show.senales_vacio"))
    end

    it "dates a reading that is not from today rather than passing it off as now" do
      observe("rsi_overbought_entered", at: 2.days.ago)

      get dashboard_path

      expect(response.body).to include(I18n.t("comun.accion.sell"))
      expect(response.body).to include("hace 2 días")
    end

    it "says the day was quiet when nothing was observed" do
      get dashboard_path

      expect(response.body).to include(I18n.t("dashboard.show.senales_vacio"))
    end
  end

  describe "the sentiment carousel" do
    it "renders a card per index the instance has actually fetched" do
      create(:fear_greed_reading, index_type: "crypto", value: 68, fetched_at: 2.days.ago.midday)
      create(:fear_greed_reading, index_type: "crypto", value: 72, fetched_at: Time.current)

      get dashboard_path

      expect(response.body).to include(ERB::Util.html_escape(I18n.t("dashboard.show.fear_greed_crypto")))
      expect(response.body).to include(">72<")
      expect(response.body).to include("+4 vs ayer")
      expect(response.body).not_to include(ERB::Util.html_escape(I18n.t("dashboard.show.fear_greed_stocks")))
    end
  end

  describe "the radar" do
    # Inherited from the retired caching spec, under a name that does not lie:
    # nothing on this screen is fragment-cached, so what this proves is that a
    # price change reaches the row.
    it "reflects a price change on the next visit" do
      asset = with_day_change(create(:asset, :stock, symbol: "BUST", currency: "USD",
                                                    current_price: 100.0), 1.25)
      create(:watchlist_item, user: user, asset: asset)

      get dashboard_path
      expect(response.body).to include("USD 100.00")

      asset.update!(current_price: 150.0)

      get dashboard_path
      expect(response.body).to include("USD 150.00")
    end

    # D69: the Radar asks what needs attention today, and both row kinds answer
    # it with the movement — so the movement takes the primary slot on both.
    it "leads a holding with the day's move and demotes what it is worth" do
      asset = with_day_change(mxn_asset(symbol: "WALMEX", current_price: 70), 1.5)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get dashboard_path

      expect(response.body).to match(%r{text-sm font-bold text-positive">\s*\+1\.5%\s*</p>})
      expect(response.body).to match(%r{text-xs text-fg-subtle">\s*7,000\s*</p>})
    end

    it "leads a watched row with the day's move and demotes the quote" do
      asset = with_day_change(create(:asset, :stock, symbol: "AAPL", currency: "USD",
                                                    current_price: 182.50), -2.0)
      create(:watchlist_item, user: user, asset: asset)

      get dashboard_path

      expect(response.body).to match(%r{text-sm font-bold text-negative">\s*−2\.0%\s*</p>})
      expect(response.body).to match(%r{text-xs text-fg-subtle">\s*USD 182\.50\s*</p>})
    end

    it "keeps the quote leading on Activos, where the same partial serves a different question" do
      asset = with_day_change(create(:asset, :stock, symbol: "AAPL", currency: "USD",
                                                    current_price: 182.50), -2.0)
      create(:watchlist_item, user: user, asset: asset)

      get assets_path(tab: "watchlist")

      expect(response.body).to match(%r{text-sm font-bold text-fg-default">\s*USD 182\.50\s*</p>})
      expect(response.body).to match(%r{text-xs text-negative">\s*−2\.0%\s*</p>})
    end

    # ADR-021: computed from two closes, so it means the same thing whichever
    # provider answered. X13 deleted the column this used to be contrasted
    # against, which is why the decoy value is gone from here.
    it "reports the day change computed from two closes" do
      asset = with_day_change(mxn_asset(symbol: "WALMEX", current_price: 70), 1.5)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get dashboard_path

      expect(response.body).to match(%r{text-sm font-bold text-positive">\s*\+1\.5%\s*</p>})
    end

    # Negative, and the one behaviour X13 actually changed: with the provider
    # column gone there is nothing to fall back on, so an asset without two
    # closes has no day change — and the radar, which only carries what moved,
    # leaves it out rather than showing a number it cannot compute.
    it "leaves out an asset that has only one close" do
      recien = mxn_asset(symbol: "RECIEN", current_price: 70)
      create(:asset_price_history, asset: recien, date: Date.current,
                                   open: 70, high: 70, low: 70, close: 70)
      movido = with_day_change(mxn_asset(symbol: "MOVIDO", current_price: 100), 2.0)
      [ recien, movido ].each { |asset| create(:watchlist_item, user: user, asset: asset) }

      get dashboard_path
      radar = response.body.split(I18n.t("dashboard.show.radar_titulo")).last

      expect(radar).to include("MOVIDO")
      expect(radar).not_to include("RECIEN")
    end

    # The radar is ordered by the size of the move, so the number it sorts on
    # has to be the number the row shows — the defect X13 belongs to.
    it "orders the rows by the same figure the rows display" do
      loud  = with_day_change(mxn_asset(symbol: "LOUD", current_price: 100), 4.0)
      quiet = with_day_change(mxn_asset(symbol: "QUIET", current_price: 100), 1.0)
      [ loud, quiet ].each { |asset| create(:watchlist_item, user: user, asset: asset) }

      get dashboard_path
      radar = response.body.split(I18n.t("dashboard.show.radar_titulo")).last

      expect(radar.scan(/LOUD|QUIET/).uniq).to eq(%w[LOUD QUIET])
      expect(radar.scan(/[+−]\d+\.\d%/).first(2)).to eq(%w[+4.0% +1.0%])
    end

    # A CETES that is about to mature has no 24h move to lead with, and the
    # radar's own sort already puts it first.
    it "leads a maturing fixed-income row with its maturity" do
      cetes = with_day_change(create(:asset, :fixed_income, symbol: "CETES28", currency: "MXN"), 0)
      create(:position, portfolio: portfolio, asset: cetes, shares: 100, avg_cost: 9.5,
                        status: :open, maturity_date: 3.days.from_now.to_date)

      get dashboard_path

      expect(response.body).to match(%r{text-sm font-bold text-warning-fg">\s*vence en 3 días\s*</p>})
    end

    # X15: the sparkline used to read PriceSeries once per row.
  end

  # Every link on this screen pointed at Activos, under three labels, because
  # each was written while its real destination was unbuilt or deleted.
  describe "where its links go" do
    before do
      asset = mxn_asset(symbol: "HELD", current_price: 10)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 8, status: :open)
      get dashboard_path
    end

    it "sends the patrimonio strip to the Consolidado" do
      expect(response.body).to include("href=\"#{portfolio_path}\"")
    end

    it "sends the Radar to Activos" do
      expect(response.body).to include("href=\"#{assets_path}\"")
    end

    it "offers no link out of Movimientos, which has no screen to reach" do
      expect(response.body).not_to include("Ver más")
    end
  end

  describe "the patrimonio strip and late capture" do
    # This screen rendered "+20.0% hoy" for a purchase recorded late.
    it "does not report a backdated purchase as today's move" do
      held = mxn_asset(symbol: "HELD", current_price: 10)
      create(:position, portfolio: portfolio, asset: held, shares: 500, avg_cost: 10, status: :open)
      portfolio.snapshots.create!(date: Date.yesterday, currency: "MXN",
                                  total_value: 5_000)
      mxn_asset(symbol: "NEW", current_price: 10)

      Trading::UseCases::ExecuteTrade.call(user: user, params: {
        asset_symbol: "NEW", side: "buy", shares: 100,
        price_per_share: 10, executed_at: Date.yesterday.to_s
      })

      get dashboard_path

      expect(response.body).to include("+0.0% hoy")
      expect(response.body).not_to include("+20.0% hoy")
    end
  end

  describe "the retired dashboard surface" do
    it "no longer routes the lazy sub-frames it used to" do
      %w[/dashboard/news_feed /dashboard/trending /dashboard/notable_observations].each do |path|
        get path
        expect(response).to have_http_status(:not_found), "#{path} still responds"
      end
    end
  end
end
