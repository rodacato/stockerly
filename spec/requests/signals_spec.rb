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
    it "lifts the Panorama's three-row, three-day cap" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      5.times { |i| observation(held, days_ago: i) }

      get "/signals"

      # The Panorama asks for 3 over 3 days; this screen asks for a week.
      expect(response.body.scan("HELD").size).to be >= 5
    end

    it "groups the readings by the day they were observed" do
      held = create(:asset, :stock, symbol: "HELD", currency: "USD")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      observation(held, days_ago: 0)
      observation(held, days_ago: 1)

      get "/signals"

      expect(response.body).to include("Hoy", "Ayer")
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
