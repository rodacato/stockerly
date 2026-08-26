require "rails_helper"

RSpec.describe "Activos › Rastreados", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  describe "GET /tracked" do
    it "shows the daily budget the sync job actually spends" do
      create_list(:system_log, 3, task_name: "Fundamentals: AAPL", severity: :success)

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

      expect(response.body).to include("Poseo", "Sigo", "Rastreado")
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
      expect(flash[:notice]).to eq("GOOGL se agregó a Rastreados.")
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
      create_list(:system_log, 4, task_name: "Fundamentals: X", severity: :success)

      expect(MarketData::Domain::FundamentalsBudget.today.used).to eq(4)
      expect(SyncAllFundamentalsJob::DAILY_BUDGET).to eq(MarketData::Domain::FundamentalsBudget::DAILY_LIMIT)
    end

    it "never reports negative headroom" do
      budget = MarketData::Domain::FundamentalsBudget.new(used: 40)

      expect(budget.remaining).to eq(0)
      expect(budget).to be_exhausted
      expect(budget.used_percent).to eq(100)
    end
  end
end
