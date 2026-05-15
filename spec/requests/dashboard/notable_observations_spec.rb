require "rails_helper"

RSpec.describe "Dashboard — Notable Observations (#40 JTBD #6)", type: :request do
  let(:user) { create(:user, email: "trader@example.com", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock, current_price: 145.0) }
  let!(:nvda) { create(:asset, symbol: "NVDA", name: "NVIDIA Corp.", asset_type: :stock, current_price: 800.0) }
  let!(:msft) { create(:asset, symbol: "MSFT", name: "Microsoft", asset_type: :stock, current_price: 400.0) }

  before { login_as(user) }

  describe "GET /dashboard" do
    it "renders the Notable Observations turbo frame placeholder lazily" do
      get dashboard_path
      expect(response.body).to include('id="dashboard_notable_observations"')
      expect(response.body).to include('loading="lazy"')
    end
  end

  describe "GET /dashboard/notable_observations" do
    context "when the user watches AAPL and holds NVDA" do
      before do
        create(:watchlist_item, user: user, asset: aapl)
        create(:position, portfolio: portfolio, asset: nvda, shares: 5)
      end

      it "lists observations only for watched + held assets (ADR-002 user filter)" do
        create(:technical_observation, asset: aapl, observation_type: "rsi_oversold_entered", observed_at: 1.day.ago)
        create(:technical_observation, asset: nvda, observation_type: "ma200_crossed_below", observed_at: 2.days.ago)
        # MSFT is neither held nor watched — must NOT appear.
        create(:technical_observation, asset: msft, observation_type: "bb_upper_breached", observed_at: 1.hour.ago)

        get dashboard_notable_observations_path

        expect(response.body).to include("AAPL")
        expect(response.body).to include("NVDA")
        expect(response.body).not_to include("MSFT")
        expect(response.body).not_to include("Microsoft")
      end

      it "uses descriptive copy per ADR-001 (no imperative verbs)" do
        create(:technical_observation, asset: aapl, observation_type: "rsi_oversold_entered", observed_at: 1.hour.ago)

        get dashboard_notable_observations_path
        expect(response.body).to include("entered oversold zone")

        body = response.body
        expect(body).not_to match(/\b(buy|sell|rebalance|consider)\b/i)
        expect(body).not_to match(/you should|time to/i)
      end

      it "excludes observations older than 14 days" do
        create(:technical_observation, asset: aapl, observation_type: "rsi_oversold_entered", observed_at: 1.hour.ago)
        create(:technical_observation, asset: aapl, observation_type: "rsi_oversold_exited", observed_at: 20.days.ago)

        get dashboard_notable_observations_path
        expect(response.body).to include("entered oversold zone")
        expect(response.body).not_to include("exited oversold zone")
      end

      it "renders nothing visible when the user-filtered set is empty" do
        # No observations for AAPL or NVDA; one for MSFT (not in scope).
        create(:technical_observation, asset: msft, observation_type: "rsi_oversold_entered", observed_at: 1.hour.ago)

        get dashboard_notable_observations_path
        expect(response.body).not_to include("Notable Observations")
      end
    end

    context "when the user has no watchlist or positions" do
      it "renders nothing visible (no observations to filter against)" do
        # Even if observations exist globally, an empty asset_ids set means
        # the section stays hidden.
        create(:technical_observation, asset: aapl, observation_type: "rsi_oversold_entered", observed_at: 1.hour.ago)

        get dashboard_notable_observations_path
        expect(response.body).not_to include("Notable Observations")
      end
    end
  end
end
