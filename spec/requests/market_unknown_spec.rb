require "rails_helper"

# D125: a symbol opened by URL that the catalogue lacks offers the import
# instead of sending the reader back to Activos with a flash.
RSpec.describe "An asset the catalogue lacks", type: :request do
  let(:user) { create(:user) }

  before do
    create(:integration, provider_name: "Yahoo Finance")
    login_as(user)
  end

  it "offers to track the listing Yahoo has under that exact symbol" do
    stub_yfinance_search("ASTS", results: [
      yfinance_match(symbol: "ASTS", name: "AST SpaceMobile, Inc.", exchange: "NASDAQ"),
      yfinance_match(symbol: "ASTX", name: "Tradr 2X Long ASTS Daily ETF", quote_type: "ETF", exchange: "BATS Trading")
    ])

    get market_asset_path("asts")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("No encontré ese activo.", "ASTS no está en tu catálogo. Yahoo Finance sí lo tiene:",
                                     "AST SpaceMobile, Inc. · NASDAQ", %(name="return_to" value="market"))
    expect(response.body).not_to include("ASTX")
  end

  # Negative: a near match is not the asset that was asked for.
  it "offers nothing when Yahoo has no listing under that symbol" do
    stub_yfinance_search("ZZQX", results: [ yfinance_match(symbol: "ZZQXY", name: "Something Else") ])

    get market_asset_path("ZZQX")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("No encontré ese activo.")
    expect(response.body).not_to include("Rastrear", "Yahoo Finance sí lo tiene")
  end

  it "says so when Yahoo does not answer" do
    stub_yfinance_search_failure("ASTS")

    get market_asset_path("ASTS")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("No encontré ese activo.",
                                     "La búsqueda en Yahoo Finance no responde. Intenta de nuevo en un momento.")
  end
end
