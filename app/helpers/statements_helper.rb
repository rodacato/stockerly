module StatementsHelper
  # Display labels for the three financial-statement tables on /market/:symbol.
  # Translated to es-MX per S11 #148 — matches BMV-emisora nomenclature so MX
  # investors who already read public-issuer reports recognize the terms.
  # Enum keys (:totalRevenue, :grossProfit, etc.) are NOT translated — those
  # map directly to Alpha Vantage JSON keys and changing them would break the
  # gateway-to-view contract.
  INCOME_LINE_ITEMS = [
    { section: "Ingresos y rentabilidad" },
    { key: "totalRevenue", label: "Ingresos", bold: true },
    { key: "costOfRevenue", label: "Costo de ventas", indent: true },
    { key: "costofGoodsAndServicesSold", label: "Costo de mercancías vendidas", indent: true },
    { key: "grossProfit", label: "Utilidad bruta", bold: true, margin_key: "grossProfitMargin" },
    { section: "Desempeño operativo" },
    { key: "operatingExpenses", label: "Gastos operativos" },
    { key: "researchAndDevelopment", label: "Gastos de I+D", indent: true },
    { key: "sellingGeneralAndAdministrative", label: "Gastos generales, de venta y administración", indent: true },
    { key: "operatingIncome", label: "Utilidad de operación", bold: true, accent: true, margin_key: "operatingMargin" },
    { key: "ebitda", label: "EBITDA", bold: true },
    { section: "Resultado final" },
    { key: "incomeBeforeTax", label: "Utilidad antes de impuestos" },
    { key: "incomeTaxExpense", label: "Impuestos sobre la renta", indent: true },
    { key: "netIncome", label: "Utilidad neta", bold: true, margin_key: "netProfitMargin" },
    { key: "dilutedEPS", label: "UPA diluida", bold: true }
  ].freeze

  BALANCE_SHEET_LINE_ITEMS = [
    { section: "Activos" },
    { key: "totalAssets", label: "Activos totales", bold: true },
    { key: "totalCurrentAssets", label: "Activo circulante", indent: true },
    { key: "cashAndCashEquivalentsAtCarryingValue", label: "Efectivo y equivalentes", indent: true },
    { key: "shortTermInvestments", label: "Inversiones de corto plazo", indent: true },
    { key: "currentNetReceivables", label: "Cuentas por cobrar", indent: true },
    { key: "inventory", label: "Inventarios", indent: true },
    { key: "totalNonCurrentAssets", label: "Activo no circulante", indent: true },
    { key: "propertyPlantEquipment", label: "Propiedad, planta y equipo", indent: true },
    { key: "goodwill", label: "Crédito mercantil", indent: true },
    { section: "Pasivos" },
    { key: "totalLiabilities", label: "Pasivos totales", bold: true },
    { key: "totalCurrentLiabilities", label: "Pasivo circulante", indent: true },
    { key: "shortTermDebt", label: "Deuda de corto plazo", indent: true },
    { key: "longTermDebt", label: "Deuda de largo plazo", indent: true },
    { section: "Capital" },
    { key: "totalShareholderEquity", label: "Capital contable", bold: true },
    { key: "retainedEarnings", label: "Utilidades retenidas", indent: true },
    { key: "commonStockSharesOutstanding", label: "Acciones en circulación" }
  ].freeze

  CASH_FLOW_LINE_ITEMS = [
    { section: "Actividades de operación" },
    { key: "operatingCashflow", label: "Flujo de efectivo operativo", bold: true },
    { key: "netIncome", label: "Utilidad neta", indent: true },
    { key: "depreciationDepletionAndAmortization", label: "Depreciación y amortización", indent: true },
    { key: "changeInOperatingLiabilities", label: "Cambio en pasivos operativos", indent: true },
    { key: "changeInOperatingAssets", label: "Cambio en activos operativos", indent: true },
    { section: "Actividades de inversión" },
    { key: "cashflowFromInvestment", label: "Flujo de inversión", bold: true },
    { key: "capitalExpenditures", label: "Inversión en activos fijos (CAPEX)", indent: true },
    { section: "Actividades de financiamiento" },
    { key: "cashflowFromFinancing", label: "Flujo de financiamiento", bold: true },
    { key: "dividendPayout", label: "Dividendos pagados", indent: true },
    { key: "commonStockRepurchased", label: "Recompra de acciones", indent: true },
    { section: "Resumen" },
    { key: "changeInCashAndCashEquivalents", label: "Cambio neto en efectivo", bold: true }
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
