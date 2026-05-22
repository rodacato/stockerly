require "rails_helper"

RSpec.describe StatementsHelper, type: :helper do
  describe "#line_items_for" do
    it "returns income statement line items in es-MX (BMV-emisora nomenclature)" do
      items = helper.line_items_for(:income_statement)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Ingresos", "Utilidad bruta", "Utilidad de operación", "Utilidad neta")
      expect(labels).to include("UPA diluida")
    end

    it "returns balance sheet line items in es-MX" do
      items = helper.line_items_for(:balance_sheet)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Activos totales", "Pasivos totales", "Capital contable")
      expect(labels).to include("Efectivo y equivalentes", "Crédito mercantil")
    end

    it "returns cash flow line items in es-MX" do
      items = helper.line_items_for(:cash_flow)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Flujo de efectivo operativo",
                                "Inversión en activos fijos (CAPEX)",
                                "Cambio neto en efectivo")
    end

    it "translates the section headings to es-MX" do
      income_sections = helper.line_items_for(:income_statement).select { |i| i[:section] }.map { |i| i[:section] }
      balance_sections = helper.line_items_for(:balance_sheet).select { |i| i[:section] }.map { |i| i[:section] }
      cashflow_sections = helper.line_items_for(:cash_flow).select { |i| i[:section] }.map { |i| i[:section] }

      expect(income_sections).to include("Ingresos y rentabilidad", "Desempeño operativo", "Resultado final")
      expect(balance_sections).to include("Activos", "Pasivos", "Capital")
      expect(cashflow_sections).to include("Actividades de operación", "Actividades de inversión",
                                            "Actividades de financiamiento", "Resumen")
    end

    it "preserves Alpha Vantage JSON keys (enum identifiers, not translated)" do
      items = helper.line_items_for(:income_statement)
      keys = items.reject { |i| i[:section] }.map { |i| i[:key] }

      # The gateway-to-view contract is keyed on the Alpha Vantage JSON field
      # names; translating the keys would break it. Translation lives on :label.
      expect(keys).to include("totalRevenue", "grossProfit", "operatingIncome",
                              "netIncome", "dilutedEPS")
    end
  end

  describe "#format_statement_value" do
    it "formats large values as abbreviated currency" do
      expect(helper.format_statement_value(394_328_000_000)).to eq("$394.3B")
    end

    it "returns em dash for nil values" do
      expect(helper.format_statement_value(nil)).to eq("—")
    end

    it "returns em dash for None strings" do
      expect(helper.format_statement_value("None")).to eq("—")
    end
  end
end
