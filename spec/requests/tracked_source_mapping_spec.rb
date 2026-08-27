require "rails_helper"

RSpec.describe "Tracked · the row for an asset no source can name", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let!(:asset) { create(:asset, :mexican, symbol: "WALMEX.MX", name: "Walmart de México", sync_status: :active) }

  before do
    login_as(user)
    create(:integration, provider_name: "DataBursatil", api_key_encrypted: "test_token")
  end

  def stub_serie(name, body, status: 200)
    stub_request(:get, "https://api.databursatil.com/v2/cotizaciones")
      .with(query: hash_including("emisora_serie" => name))
      .to_return(status: status, headers: { "Content-Type" => "application/json" }, body: body.to_json)
  end

  describe "the row" do
    it "says nothing extra while the asset is being priced" do
      get tracked_assets_path

      expect(response.body).not_to include("sin cotizar")
    end

    it "says the asset is not being priced, and offers the name to fix it" do
      asset.update!(last_sync_error: SyncBulkBmvJob::UNNAMED)

      get tracked_assets_path

      expect(response.body).to include("sin cotizar")
      expect(response.body).to include("no reconoce")
      expect(response.body).to include("Guardamos el nombre solo si la fuente contesta con él")
    end

    # Pausing is the owner's choice; this is the instance failing. D46 draws
    # them apart on purpose, and the dimming is what separates them.
    it "does not dim it the way a paused row is dimmed" do
      asset.update!(last_sync_error: SyncBulkBmvJob::UNNAMED)

      get tracked_assets_path
      unnamed = response.body

      asset.update!(last_sync_error: nil, sync_status: :disabled)
      get tracked_assets_path

      expect(unnamed).not_to include("opacity-60")
      expect(response.body).to include("opacity-60")
    end
  end

  describe "PATCH the mapping" do
    it "saves the name the provider answers to and stops flagging the row" do
      asset.update!(last_sync_error: SyncBulkBmvJob::UNNAMED)
      stub_serie("WALMEX*", { "WALMEX*" => { "bmv" => { "u" => "47.81", "v" => "1", "f" => Time.current.iso8601 } } })

      patch map_source_symbol_asset_path(asset), params: { provider: "DataBursatil", symbol: "WALMEX*" }

      expect(asset.reload.provider_symbols["DataBursatil"]).to eq("WALMEX*")
      expect(asset.last_sync_error).to be_nil
      follow_redirect!
      expect(response.body).not_to include("sin cotizar")
    end

    # The negative that matters: a mapping the provider does not answer to
    # would fail the sync on a name the owner believes is right.
    it "keeps the row flagged and says so when the provider refuses the name" do
      asset.update!(last_sync_error: SyncBulkBmvJob::UNNAMED)
      stub_serie("WALMEXX", "Emisoras y/o series desconocidas", status: 400)

      patch map_source_symbol_asset_path(asset), params: { provider: "DataBursatil", symbol: "WALMEXX" }

      expect(asset.reload.provider_symbols).to be_empty
      follow_redirect!
      expect(response.body).to include("no reconoce")
    end

    it "404s to the list rather than raising for an asset that is gone" do
      patch map_source_symbol_asset_path(id: 0), params: { provider: "DataBursatil", symbol: "X" }

      expect(response).to redirect_to(tracked_assets_path)
    end
  end
end
