require "rails_helper"

RSpec.describe "Activos › Tracked", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  describe "GET /tracked" do
    it "shows the daily budget the sync job actually spends" do
      create(:integration, provider_name: "Alpha Vantage", daily_api_calls: 3,
                           daily_call_limit: 25, calls_reset_at: Time.current)

      get tracked_assets_path

      expect(response.body).to include("3 de 25 llamadas usadas")
    end

    it "labels each asset with the tier that decides its sync priority" do
      held = create(:asset, :stock, symbol: "HELD", currency: "MXN")
      followed = create(:asset, :stock, symbol: "FOLLOWED", currency: "MXN")
      create(:asset, :stock, symbol: "PLAIN", currency: "MXN")
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
      create(:watchlist_item, user: user, asset: followed)

      get tracked_assets_path

      expect(response.body).to include("Holdings", "Watchlist", "Tracked")
    end

    it "offers Seguir only on the tier that has not crossed yet" do
      create(:asset, :stock, symbol: "PLAIN", currency: "MXN")
      followed = create(:asset, :stock, symbol: "FOLLOWED", currency: "MXN")
      create(:watchlist_item, user: user, asset: followed)

      get tracked_assets_path

      # Counting forms, not the word: the screen's intro copy also says "Seguir".
      expect(response.body.scan(%r{action="/watchlist_items}).size).to eq(1)
    end
  end

  describe "PATCH /tracked/:id/toggle_sync" do
    let!(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", sync_status: :active) }

    it "pauses an asset and says the budget is freed" do
      patch toggle_sync_asset_path(asset)

      expect(asset.reload).to be_disabled
      expect(flash[:notice]).to eq("NVDA en pausa. Su presupuesto queda libre.")
    end

    it "resumes a paused asset" do
      asset.update!(sync_status: :disabled)

      patch toggle_sync_asset_path(asset)

      expect(asset.reload).to be_active
    end

    it "reports a missing asset instead of raising" do
      patch toggle_sync_asset_path(id: 0)

      expect(response).to redirect_to(tracked_assets_path)
      expect(flash[:alert]).to eq("No encontré ese activo.")
    end
  end

  describe "POST /tracked" do
    it "adds an asset to the catalogue and says so" do
      expect {
        post track_asset_path, params: {
          asset: { symbol: "GOOGL", name: "Alphabet Inc.", asset_type: "stock",
                   country: "US", exchange: "NASDAQ", sector: "Technology" }
        }
      }.to change(Asset, :count).by(1)

      expect(response).to redirect_to(tracked_assets_path)
      expect(flash[:notice]).to eq("GOOGL se agregó a Tracked.")
    end

    it "reports the validation error instead of creating a half-formed asset" do
      expect {
        post track_asset_path, params: { asset: { symbol: "", name: "", asset_type: "" } }
      }.not_to change(Asset, :count)

      expect(response).to redirect_to(tracked_assets_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /tracked/:id" do
    it "drops the asset out of the catalogue" do
      asset = create(:asset, :stock, symbol: "GONE", currency: "USD")

      expect { delete untrack_asset_path(asset) }.to change(Asset, :count).by(-1)

      expect(response).to redirect_to(tracked_assets_path)
      expect(flash[:notice]).to eq("GONE se quitó del catálogo.")
    end

    it "reports a missing asset instead of raising" do
      delete untrack_asset_path(id: 0)

      expect(response).to redirect_to(tracked_assets_path)
      expect(flash[:alert]).to eq("No encontré ese activo.")
    end
  end

  describe "the budget the screen shows and the job spends" do
    it "is one calculation, not two" do
      create(:integration, provider_name: "Alpha Vantage", daily_api_calls: 4,
                           daily_call_limit: 25, calls_reset_at: Time.current)

      expect(MarketData::Domain::FundamentalsBudget.today.used).to eq(4)

      # Neither orchestrator carries a budget number of its own any more. Two
      # constants were two sources of truth, and the statements one drifted
      # into counting log lines instead of calls.
      expect(SyncAllFundamentalsJob.const_defined?(:DAILY_BUDGET, false)).to be false
      expect(SyncAllStatementsJob.const_defined?(:DAILY_BUDGET, false)).to be false
    end

    # A statements sync spends three calls and logs one, and failures spend
    # quota without logging success at all. Counting logs missed both.
    it "counts the calls made, not the successes logged" do
      create(:integration, provider_name: "Alpha Vantage", daily_api_calls: 9,
                           daily_call_limit: 25, calls_reset_at: Time.current)
      create_list(:system_log, 3, task_name: "Fundamentals: X", severity: :success)

      expect(MarketData::Domain::FundamentalsBudget.today.used).to eq(9)
    end

    # The counter resets lazily on the next call, so a stale stamp would
    # otherwise carry yesterday's spend into today's headroom.
    it "ignores a counter that was never reset today" do
      create(:integration, provider_name: "Alpha Vantage", daily_api_calls: 25,
                           daily_call_limit: 25, calls_reset_at: 2.days.ago)

      expect(MarketData::Domain::FundamentalsBudget.today.used).to eq(0)
    end

    it "never reports negative headroom" do
      budget = MarketData::Domain::FundamentalsBudget.new(used: 40)

      expect(budget.remaining).to eq(0)
      expect(budget).to be_exhausted
      expect(budget.used_percent).to eq(100)
    end
  end
end
