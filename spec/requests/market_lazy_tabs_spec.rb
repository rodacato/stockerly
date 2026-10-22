require "rails_helper"

# Lazy tab endpoints (S10 #93). Estados financieros is the one tab the
# asset detail loads as a lazy turbo_frame.
RSpec.describe "Market lazy-loaded tabs", type: :request do
  let!(:user) { create(:user, email: "lazytabs@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "MSFT", name: "Microsoft Corp.", current_price: 430.0, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders the lazy Turbo Frame placeholder for the Estados financieros tab when data exists" do
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 6, 30), fiscal_year: 2024,
        data: { "total_revenue" => "245000000000" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="asset_statements_tab"')
      expect(response.body).to include('loading="lazy"')
    end
  end

  describe "GET /market/:symbol/statements_tab" do
    it "renders statements content inside a Turbo Frame" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("asset_statements_tab")
    end

    it "shows an es-MX empty state when no statements exist" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("Sin estados financieros")
    end

    # S11 #148: StatementsHelper line-item labels translated to BMV-emisora
    # nomenclature. Confirms the Estados financieros tab now renders the
    # es-MX labels rather than the previous English copy.
    context "with annual statements populated" do
      before do
        create(:financial_statement, asset: asset,
          statement_type: :income_statement, period_type: :annual,
          fiscal_date_ending: Date.new(2024, 6, 30), fiscal_year: 2024,
          data: {
            "total_revenue" => "245000000000",
            "gross_profit" => "169000000000",
            "operating_income" => "109000000000",
            "net_income" => "88000000000"
          })
        create(:financial_statement, asset: asset,
          statement_type: :balance_sheet, period_type: :annual,
          fiscal_date_ending: Date.new(2024, 6, 30), fiscal_year: 2024,
          data: {
            "total_assets" => "411000000000",
            "total_liabilities_net_minority_interest" => "243000000000",
            "total_shareholder_equity" => "168000000000",
            "ordinary_shares_number" => "15200000000"
          })
        create(:financial_statement, asset: asset,
          statement_type: :cash_flow, period_type: :annual,
          fiscal_date_ending: Date.new(2024, 6, 30), fiscal_year: 2024,
          data: {
            "operating_cashflow" => "118000000000",
            "capital_expenditures" => "44000000000",
            "changes_in_cash" => "5000000000"
          })
      end

      it "renders income statement labels in es-MX (Ingresos, Utilidad bruta, ...)" do
        get market_asset_statements_tab_path(asset.symbol)

        expect(response.body).to include("Ingresos")
        expect(response.body).to include("Utilidad bruta")
        expect(response.body).to include("Utilidad de operación")
        expect(response.body).to include("Utilidad neta")
      end

      it "renders balance sheet labels in es-MX" do
        get market_asset_statements_tab_path(asset.symbol)

        expect(response.body).to include("Activos totales")
        expect(response.body).to include("Pasivos totales")
        expect(response.body).to include("Capital contable")
      end

      it "renders cash flow labels in es-MX" do
        get market_asset_statements_tab_path(asset.symbol)

        expect(response.body).to include("Flujo de efectivo operativo")
        expect(response.body).to include("CAPEX")
        expect(response.body).to include("Cambio neto en efectivo")
      end

      it "renders the share count as a count, not money" do
        get market_asset_statements_tab_path(asset.symbol)

        expect(response.body).to include(">15.2B<")
        expect(response.body).not_to include("#{asset.currency} 15.2B")
      end

      it "renders the es-MX 'Concepto' column header instead of 'Line Item'" do
        get market_asset_statements_tab_path(asset.symbol)
        expect(response.body).to include("Concepto")
        expect(response.body).not_to include("Line Item")
      end
    end
  end

  # JTBD #8: every line the three statements render opens what it is and how to
  # read it. The keys are built from the line, so this is the guarantee that
  # each one has a full entry whose name matches the label in the table.
  describe "the glossary behind each statement line" do
    include StatementsHelper

    before do
      %w[income_statement balance_sheet cash_flow].each do |type|
        create(:financial_statement, asset: asset, statement_type: type, period_type: :annual,
               data: { "total_revenue" => "391035000000" })
      end
    end

    it "explains every line, under the name the table gives it" do
      get market_asset_statements_tab_path(asset.symbol)

      %w[income_statement balance_sheet cash_flow].each do |type|
        line_items_for(type).select { |item| item[:key] }.each do |item|
          entry = I18n.t("market.glosario.#{item[:key]}", raise: true)

          expect(entry[:nombre]).to eq(item[:label])
          expect(response.body).to include(%(popovertarget="glosario-#{type}-#{item[:key]}"))
          expect(response.body).to include(CGI.escapeHTML(entry[:desc]))
        end
      end
    end

    it "explains nothing when there are no statements" do
      FinancialStatement.delete_all

      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).not_to include("popovertarget=")
    end
  end
end
