require "rails_helper"

RSpec.describe StatementsHelper, type: :helper do
  describe "#line_items_for" do
    it "returns income statement line items" do
      items = helper.line_items_for(:income_statement)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Revenue", "Gross Profit", "Operating Income", "Net Income")
    end

    it "returns balance sheet line items" do
      items = helper.line_items_for(:balance_sheet)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Total Assets", "Total Liabilities", "Shareholder Equity")
    end

    it "returns cash flow line items" do
      items = helper.line_items_for(:cash_flow)
      labels = items.reject { |i| i[:section] }.map { |i| i[:label] }

      expect(labels).to include("Operating Cash Flow", "Capital Expenditures", "Net Change in Cash")
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
