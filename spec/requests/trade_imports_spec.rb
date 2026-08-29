require "rails_helper"

RSpec.describe "Trade imports", type: :request do
  let(:user) { create(:user, preferred_currency: "USD", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:vt) { create(:asset, :etf, symbol: "VT", currency: "USD") }

  let(:header) { "asset_symbol,side,shares,price_per_share,executed_at,external_id" }
  let(:good) { "#{header}\nVT,buy,2.0,100.0,2025-12-08,order-1" }

  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico")
    login_as(user)
  end

  describe "GET /trades/import" do
    it "renders the form" do
      get new_trade_import_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Importar movimientos")
    end

    it "is behind authentication" do
      delete "/logout"
      get new_trade_import_path

      expect(response).to redirect_to("/login")
    end
  end

  describe "POST /trades/import/preview" do
    it "reports the batch without writing anything" do
      expect {
        post preview_trade_import_path, params: { contenido: good }
      }.not_to change(Trade, :count)

      expect(response.body).to include("Nada se ha guardado todavía")
      expect(response.body).to include("VT")
    end

    it "accepts an uploaded file as well as pasted text" do
      file = Rack::Test::UploadedFile.new(StringIO.new(good), "text/csv", original_filename: "trades.csv")

      post preview_trade_import_path, params: { archivo: file }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nada se ha guardado todavía")
    end

    it "refuses the whole batch when a symbol is unknown, naming every one" do
      csv = "#{good}\nNOPE,buy,1.0,10.0,2025-12-08,order-2\nALSONOPE,buy,1.0,10.0,2025-12-08,order-3"

      post preview_trade_import_path, params: { contenido: csv }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ALSONOPE").and include("NOPE")
      expect(response.body).to include("No puedo importar todavía")
      expect(Trade.count).to eq(0)
    end

    # An uploaded file reads back as ASCII-8BIT, and the unknown-symbol screen
    # builds a checkbox id from each symbol. The existing upload example only
    # ever exercised the happy path, so a binary symbol never reached the view.
    it "renders the unknown-symbol screen for an uploaded file, not only pasted text" do
      csv = "#{good}\nALAB,buy,1.0,10.0,2025-12-08,order-2"
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "trades.csv")

      post preview_trade_import_path, params: { archivo: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(value="ALAB"))
      expect(response.body).to include("No puedo importar todavía")
    end

    it "rejects a file whose required columns are missing" do
      post preview_trade_import_path, params: { contenido: "foo,bar\n1,2" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Faltan columnas")
    end
  end

  describe "POST /trades/import" do
    it "imports the batch and lands on the portfolio" do
      expect {
        post trade_imports_path, params: { contenido: good }
      }.to change(Trade, :count).by(1)

      expect(response).to redirect_to(portfolio_path)
      expect(flash[:notice]).to include("1 movimiento")
    end

    it "does not write a second time when the same file is confirmed twice" do
      post trade_imports_path, params: { contenido: good }

      expect {
        post trade_imports_path, params: { contenido: good }
      }.not_to change(Trade, :count)
    end

    it "writes nothing when the batch is refused" do
      csv = "#{header}\nNOPE,buy,1.0,10.0,2025-12-08,order-9"

      expect {
        post trade_imports_path, params: { contenido: csv }
      }.not_to change(Trade, :count)

      expect(response).to redirect_to(new_trade_import_path)
      expect(flash[:alert]).to be_present
    end
  end

  # The view builds this key from the Failure tag, so i18n-tasks cannot see it.
  # This is the guarantee that replaces the scan.
  describe "every refusal the importer can return" do
    it "resolves to a phrase" do
      %i[invalid_rows unknown_symbols unsupported_asset_type missing_fx_history not_found].each do |tag|
        expect(I18n.t("trade_imports.preview.rechazo.#{tag}", count: 2, default: nil))
          .to be_present, "no phrase for Failure tag :#{tag}"
      end
    end
  end

  # One dead ticker held up 49 good trades. The refusal stays the default; this
  # is the door out of it, and it only opens when asked.
  describe "importing without the symbols it cannot resolve" do
    let(:mixed) { "#{good}\nNOPE,buy,1.0,10.0,2025-12-08,order-2\nNOPE,buy,2.0,10.0,2025-12-09,order-3" }

    it "offers the way out, naming what it would cost" do
      post preview_trade_import_path, params: { contenido: mixed }

      expect(response.body).to include("Importar solo 1 movimiento")
      expect(response.body).to include("se quedan sin importar 2")
    end

    it "previews the rest and reports what it would leave behind" do
      post preview_trade_import_path, params: { contenido: mixed, skip_unknown: "1" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nada se ha guardado todavía")
      expect(Trade.count).to eq(0)
    end

    it "imports the rest and leaves the unknown symbol's trades out entirely" do
      post trade_imports_path, params: { contenido: mixed, skip_unknown: "1" }

      expect(response).to redirect_to(portfolio_path)
      expect(Trade.count).to eq(1)
      expect(Trade.first.asset.symbol).to eq("VT")
    end

    # Dropping some rows of a symbol would leave that position wrong by a
    # number, which is worse than not having it.
    it "drops whole symbols, never single rows" do
      csv = "#{mixed}\nVT,buy,1.0,120.0,2025-12-09,order-4"

      post trade_imports_path, params: { contenido: csv, skip_unknown: "1" }

      expect(Trade.pluck(:external_id)).to contain_exactly("order-1", "order-4")
    end

    it "still refuses everything when the door was not opened" do
      post trade_imports_path, params: { contenido: mixed }

      expect(Trade.count).to eq(0)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /trades/import/tracked" do
    before { allow(ResolveTrackedSymbolsJob).to receive(:perform_later) }

    # The screen used to offer one CTA that was a link to /tracked carrying no
    # symbols, so seventeen missing tickers meant seventeen manual entries.
    it "offers every missing symbol as a checked box, not a link" do
      csv = "#{good}\nAMD,buy,1.0,10.0,2025-12-08,order-2\nALAB,buy,1.0,10.0,2025-12-08,order-3"

      post preview_trade_import_path, params: { contenido: csv }

      expect(response.body).to include(%(action="#{track_missing_trade_import_path}"))
      expect(response.body).to include(%(name="symbols[]" id="symbol_amd" value="AMD"))
      expect(response.body).to include(%(name="symbols[]" id="symbol_alab" value="ALAB"))
      expect(response.body.scan(/type="checkbox"[^>]*checked="checked"/).size).to eq(2)
    end

    # The two halves cost differently, so the row says which is which before
    # anyone spends a provider call on it.
    it "says which symbols the catalogue already knows" do
      csv = "#{good}\nAMD,buy,1.0,10.0,2025-12-08,order-2\nALAB,buy,1.0,10.0,2025-12-08,order-3"

      post preview_trade_import_path, params: { contenido: csv }

      expect(response.body).to include("en el catálogo").and include("le pregunto al proveedor")
    end

    it "creates the catalogued half and sends the rest to the job" do
      post track_missing_trade_import_path, params: { symbols: %w[AMD ALAB] }

      expect(Asset.find_by(symbol: "AMD")).to be_present
      expect(ResolveTrackedSymbolsJob).to have_received(:perform_later).with([ "ALAB" ], user.id)
      expect(response).to redirect_to(new_trade_import_path)
      expect(flash[:notice]).to include("1").and include("te aviso")
    end

    it "says the file can go back in when nothing is left pending" do
      post track_missing_trade_import_path, params: { symbols: %w[AMD] }

      expect(flash[:notice]).to eq("Di de alta 1 símbolo. Vuelve a subir tu archivo.")
      expect(ResolveTrackedSymbolsJob).not_to have_received(:perform_later)
    end

    it "refuses a submission with every box unchecked" do
      post track_missing_trade_import_path, params: {}

      expect(response).to redirect_to(new_trade_import_path)
      expect(flash[:alert]).to eq("No seleccionaste ningún símbolo.")
      expect(ResolveTrackedSymbolsJob).not_to have_received(:perform_later)
    end

    it "is behind authentication" do
      delete "/logout"

      post track_missing_trade_import_path, params: { symbols: %w[AMD] }

      expect(response).to redirect_to("/login")
      expect(Asset.find_by(symbol: "AMD")).to be_nil
    end
  end

  describe "the door" do
    it "is reachable from the assets screen" do
      get assets_path

      expect(response.body).to include(new_trade_import_path)
    end
  end
end
