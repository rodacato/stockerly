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

  describe "the door" do
    it "is reachable from the assets screen" do
      get assets_path

      expect(response.body).to include(new_trade_import_path)
    end
  end
end
