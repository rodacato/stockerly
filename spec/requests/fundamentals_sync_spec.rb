require "rails_helper"

# CKP-7's second half: the asset detail used to enqueue a sync from its GET.
# It now asks, and the block swaps itself in when the sync lands.
RSpec.describe "Asking for an asset's fundamentals", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "no longer enqueues a sync just because someone looked" do
      expect { get market_asset_path(asset.symbol) }.not_to have_enqueued_job(SyncFundamentalJob)
    end

    it "offers the reader the button instead" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.summary_tab.vacio_cta"))
      expect(response.body).to include(market_asset_fundamentals_path(asset.symbol))
    end

    it "does not offer it for an asset type no provider covers" do
      crypto = create(:asset, :crypto, symbol: "BTC", current_price: 1000, sync_status: :active)

      get market_asset_path(crypto.symbol)

      expect(response.body).to include(I18n.t("market.summary_tab.sin_fuente"))
      expect(response.body).not_to include(I18n.t("market.summary_tab.vacio_cta"))
    end
  end

  describe "POST /market/:symbol/fundamentals" do
    it "enqueues the sync and says it is on its way" do
      expect { post market_asset_fundamentals_path(asset.symbol) }
        .to have_enqueued_job(SyncFundamentalJob).with(asset.id)

      expect(response.body).to include(I18n.t("market.summary_tab.buscando_titulo"))
    end

    # The button is pressable repeatedly, which is exactly why the cooldown
    # moved with the enqueue instead of staying behind in the controller.
    it "does not enqueue again inside the cooldown" do
      asset.update!(fundamentals_synced_at: 1.minute.ago)

      expect { post market_asset_fundamentals_path(asset.symbol) }
        .not_to have_enqueued_job(SyncFundamentalJob)
    end

    it "tells the reader nothing is coming when nothing was enqueued" do
      asset.update!(fundamentals_synced_at: 1.minute.ago)

      post market_asset_fundamentals_path(asset.symbol)

      expect(response.body).not_to include(I18n.t("market.summary_tab.buscando_titulo"))
    end

    it "404s for a symbol that does not exist" do
      post market_asset_fundamentals_path("NOPE")

      expect(response).to have_http_status(:not_found)
    end
  end
end
