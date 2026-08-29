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

    describe "the budget's tier breakdown" do
      let(:counts) { Trading::UseCases::LoadTrackedAssets.call(user: user)[:tier_counts] }

      def stock(symbol, **attrs)
        create(:asset, :stock, symbol: symbol, currency: "MXN", **attrs)
      end

      def hold(asset)
        create(:position, portfolio: portfolio, asset: asset, shares: 1, avg_cost: 1, status: :open)
      end

      it "counts each rung of the ladder the sync job spends in" do
        hold(stock("HELD"))
        create(:watchlist_item, user: user, asset: stock("FOLLOWED"))
        stock("PLAIN")

        expect(counts).to eq(held: 1, followed: 1, tracked: 1)
      end

      # An asset held AND followed sits on the top rung once, not on two.
      it "puts an asset on its highest rung only" do
        both = stock("BOTH")
        hold(both)
        create(:watchlist_item, user: user, asset: both)

        expect(counts).to eq(held: 1, followed: 0, tracked: 0)
      end

      # Negative: the panel counts one provider's fundamentals quota, and
      # SyncAllFundamentalsJob only enqueues active stocks and ETFs. Crypto
      # and a disabled asset spend none of it.
      it "leaves out what cannot spend this budget" do
        create(:asset, :crypto, symbol: "BTC", currency: "USD")
        stock("OFF", sync_status: :disabled)

        expect(counts).to eq(held: 0, followed: 0, tracked: 0)
      end
    end

    describe "filtering the list" do
      before do
        create(:asset, :stock, symbol: "NVDA", name: "Nvidia Corp.", currency: "USD")
        create(:asset, :stock, symbol: "MSFT", name: "Microsoft", currency: "USD")
      end

      # AAPL is the add-form's own placeholder, so it is in every body and
      # cannot be used as a fixture here.
      def filter(query)
        get tracked_assets_path(q: query)
        response.body
      end

      it "matches on the symbol" do
        body = filter("nvda")

        expect(body).to include("NVDA")
        expect(body).not_to include("MSFT")
      end

      it "matches on the name too, since nobody remembers every ticker" do
        body = filter("microsoft")

        expect(body).to include("MSFT")
        expect(body).not_to include("NVDA")
      end

      it "says which query found nothing, rather than reading as an empty instance" do
        body = filter("zzzz")

        expect(body).to include("Sin coincidencias", "zzzz")
        expect(body).not_to include("Tu instancia aún no rastrea ningún activo")
      end

      # Negative: a blank q is not a filter. An empty search box used to be an
      # easy way to ask for everything and get nothing back.
      it "shows everything when the box is empty" do
        expect(filter("  ")).to include("NVDA", "MSFT")
      end
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
