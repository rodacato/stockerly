require "rails_helper"

RSpec.describe "Cockpit › Señales", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  def observation(asset, days_ago:, type: "rsi_oversold_entered")
    create(:technical_observation, asset: asset, observation_type: type,
                                   observed_at: days_ago.days.ago)
  end

  describe "GET /signals" do
    it "keeps Panorama lit, the screen its Ver todas link leaves from" do
      get "/signals"

      expect(Capybara.string(response.body)).to have_css("a[aria-current='page']", text: "Panorama")
    end

    it "lifts the Panorama's three-row, three-day cap" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      5.times { |i| observation(held, days_ago: i) }

      get "/signals"

      # The Panorama asks for 3 over 3 days; this screen asks for a week.
      expect(response.body.scan("HELD").size).to be >= 5
    end

    # D127: XLG crossed below its MA50 and rendered an upward arrow beside the
    # phrase saying it fell. The arrow draws the move; the row names its logic.
    describe "a row's arrow and logic" do
      def row_for(symbol, type)
        asset = create(:asset, :stock, symbol: symbol, currency: "USD")
        create(:position, portfolio: portfolio, asset: asset, shares: 1, avg_cost: 1, status: :open)
        observation(asset, days_ago: 0, type: type)
        get "/signals"
        Capybara.string(response.body).find("a[href='/market/#{symbol}']")
      end

      it "draws a fall under a moving average downward, as trend-following" do
        row = row_for("XLG", "ma50_crossed_below")

        expect(row).to have_css("[data-icon='south_east']")
        expect(row).to have_no_css("[data-icon='north_east']")
        expect(row).to have_text("vende")
        expect(row).to have_text("Tendencia")
      end

      it "draws a break of the lower band downward, as a bet on the rebound" do
        row = row_for("COIN", "bb_lower_breached")

        expect(row).to have_css("[data-icon='south_east']")
        expect(row).to have_text("compra")
        expect(row).to have_text("Rebote")
      end
    end

    it "groups the readings by the day they were observed" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      observation(held, days_ago: 0)
      observation(held, days_ago: 1)

      get "/signals"

      expect(response.body).to include("Hoy", "Ayer")
    end

    # A row under AYER that also reads "ayer" says the same thing twice.
    it "leaves the date to the heading it sits under" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      observation(held, days_ago: 1)

      get "/signals"

      expect(response.body).to include("Ayer")
      expect(response.body).not_to include(">ayer<")
    end

    it "reads what you follow, not only what you hold" do
      watched = create(:asset, :stock, symbol: "WATCHED", currency: "USD")
      create(:watchlist_item, user: user, asset: watched)
      observation(watched, days_ago: 0)

      get "/signals"

      expect(response.body).to include("WATCHED")
    end

    # The footer claims exits are not actions (ADR-013). This is that claim.
    it "leaves out an exit, which the screen says is not an action" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      observation(held, days_ago: 0, type: "rsi_overbought_exited")

      get "/signals"

      expect(response.body).not_to include("HELD")
    end

    # Negative: the window is a week, so an older reading is not the screen's.
    it "leaves out a reading older than the window" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      observation(held, days_ago: Trading::UseCases::LoadSignals::WINDOW_DAYS + 1)

      get "/signals"

      expect(response.body).not_to include("HELD")
      expect(response.body).to include("Sin señales")
    end
  end

  it "is reachable from the Panorama, which no longer hides the door" do
    get dashboard_path

    expect(response.body).to include("/signals")
  end
end
