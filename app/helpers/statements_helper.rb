module StatementsHelper
  INCOME_LINE_ITEMS = [
    { section: "Revenue & Profitability" },
    { key: "totalRevenue", label: "Revenue", bold: true },
    { key: "costOfRevenue", label: "Cost of Revenue", indent: true },
    { key: "costofGoodsAndServicesSold", label: "Cost of Goods Sold", indent: true },
    { key: "grossProfit", label: "Gross Profit", bold: true, margin_key: "grossProfitMargin" },
    { section: "Operating Performance" },
    { key: "operatingExpenses", label: "Operating Expenses" },
    { key: "researchAndDevelopment", label: "R&D Expenses", indent: true },
    { key: "sellingGeneralAndAdministrative", label: "SG&A", indent: true },
    { key: "operatingIncome", label: "Operating Income", bold: true, accent: true, margin_key: "operatingMargin" },
    { key: "ebitda", label: "EBITDA", bold: true },
    { section: "Bottom Line" },
    { key: "incomeBeforeTax", label: "Pre-Tax Income" },
    { key: "incomeTaxExpense", label: "Income Tax Expense", indent: true },
    { key: "netIncome", label: "Net Income", bold: true, margin_key: "netProfitMargin" },
    { key: "dilutedEPS", label: "Diluted EPS", bold: true }
  ].freeze

  BALANCE_SHEET_LINE_ITEMS = [
    { section: "Assets" },
    { key: "totalAssets", label: "Total Assets", bold: true },
    { key: "totalCurrentAssets", label: "Current Assets", indent: true },
    { key: "cashAndCashEquivalentsAtCarryingValue", label: "Cash & Equivalents", indent: true },
    { key: "shortTermInvestments", label: "Short-Term Investments", indent: true },
    { key: "currentNetReceivables", label: "Receivables", indent: true },
    { key: "inventory", label: "Inventory", indent: true },
    { key: "totalNonCurrentAssets", label: "Non-Current Assets", indent: true },
    { key: "propertyPlantEquipment", label: "PP&E", indent: true },
    { key: "goodwill", label: "Goodwill", indent: true },
    { section: "Liabilities" },
    { key: "totalLiabilities", label: "Total Liabilities", bold: true },
    { key: "totalCurrentLiabilities", label: "Current Liabilities", indent: true },
    { key: "shortTermDebt", label: "Short-Term Debt", indent: true },
    { key: "longTermDebt", label: "Long-Term Debt", indent: true },
    { section: "Equity" },
    { key: "totalShareholderEquity", label: "Shareholder Equity", bold: true },
    { key: "retainedEarnings", label: "Retained Earnings", indent: true },
    { key: "commonStockSharesOutstanding", label: "Shares Outstanding" }
  ].freeze

  CASH_FLOW_LINE_ITEMS = [
    { section: "Operating Activities" },
    { key: "operatingCashflow", label: "Operating Cash Flow", bold: true },
    { key: "netIncome", label: "Net Income", indent: true },
    { key: "depreciationDepletionAndAmortization", label: "Depreciation & Amortization", indent: true },
    { key: "changeInOperatingLiabilities", label: "Change in Operating Liabilities", indent: true },
    { key: "changeInOperatingAssets", label: "Change in Operating Assets", indent: true },
    { section: "Investing Activities" },
    { key: "cashflowFromInvestment", label: "Investing Cash Flow", bold: true },
    { key: "capitalExpenditures", label: "Capital Expenditures", indent: true },
    { section: "Financing Activities" },
    { key: "cashflowFromFinancing", label: "Financing Cash Flow", bold: true },
    { key: "dividendPayout", label: "Dividends Paid", indent: true },
    { key: "commonStockRepurchased", label: "Stock Buybacks", indent: true },
    { section: "Summary" },
    { key: "changeInCashAndCashEquivalents", label: "Net Change in Cash", bold: true }
  ].freeze

  def line_items_for(statement_type)
    case statement_type.to_s
    when "income_statement" then INCOME_LINE_ITEMS
    when "balance_sheet"    then BALANCE_SHEET_LINE_ITEMS
    when "cash_flow"        then CASH_FLOW_LINE_ITEMS
    else INCOME_LINE_ITEMS
    end
  end

  def format_statement_value(value)
    return "—" if value.nil? || value.to_s == "None"

    num = value.to_f
    format_large_currency(num)
  end

  def compute_margin(statements, numerator_key, denominator_key)
    statements.map do |stmt|
      num = stmt.data[numerator_key]&.to_f
      den = stmt.data[denominator_key]&.to_f
      den&.nonzero? ? (num / den * 100).round(1) : nil
    end
  end
end
