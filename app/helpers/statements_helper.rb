module StatementsHelper
  # Display labels for the three financial-statement tables on /market/:symbol.
  # Translated to es-MX per S11 #148 — matches BMV-emisora nomenclature so MX
  # investors who already read public-issuer reports recognize the terms.
  # Keys (total_revenue, gross_profit, etc.) are NOT translated — those are
  # the names SyncStatementsJob stores and changing them would break the
  # gateway-to-view contract.
  SOURCE_NAMES = { "yfinance" => "Yahoo Finance", "alpha_vantage" => "Alpha Vantage" }.freeze

  # Rows keep the source that wrote them, so an asset can still hold older
  # periods from the retired Alpha Vantage beside Yahoo's.
  def statement_sources(asset)
    asset.financial_statements.order(fiscal_date_ending: :desc).pluck(:source).uniq
         .map { |source| SOURCE_NAMES.fetch(source, source) }
         .to_sentence(two_words_connector: " y ", last_word_connector: " y ")
  end

  INCOME_LINE_ITEMS = [
    { section: "Ingresos y rentabilidad" },
    { key: "total_revenue", label: "Ingresos", bold: true },
    { key: "cost_of_revenue", label: "Costo de ventas", indent: true },
    { key: "gross_profit", label: "Utilidad bruta", bold: true, margin_key: "grossProfitMargin" },
    { section: "Desempeño operativo" },
    { key: "operating_expense", label: "Gastos operativos" },
    { key: "research_and_development", label: "Gastos de I+D", indent: true },
    { key: "selling_general_and_administration", label: "Gastos generales, de venta y administración", indent: true },
    { key: "operating_income", label: "Utilidad de operación", bold: true, accent: true, margin_key: "operatingMargin" },
    { key: "ebitda", label: "EBITDA", bold: true },
    { section: "Resultado final" },
    { key: "pretax_income", label: "Utilidad antes de impuestos" },
    { key: "tax_provision", label: "Impuestos sobre la renta", indent: true },
    { key: "net_income", label: "Utilidad neta", bold: true, margin_key: "netProfitMargin" },
    { key: "diluted_eps", label: "UPA diluida", bold: true }
  ].freeze

  BALANCE_SHEET_LINE_ITEMS = [
    { section: "Activos" },
    { key: "total_assets", label: "Activos totales", bold: true },
    { key: "total_current_assets", label: "Activo circulante", indent: true },
    { key: "cash_and_cash_equivalents", label: "Efectivo y equivalentes", indent: true },
    { key: "other_short_term_investments", label: "Inversiones de corto plazo", indent: true },
    { key: "receivables", label: "Cuentas por cobrar", indent: true },
    { key: "inventory", label: "Inventarios", indent: true },
    { key: "total_non_current_assets", label: "Activo no circulante", indent: true },
    { key: "net_ppe", label: "Propiedad, planta y equipo", indent: true },
    { key: "goodwill", label: "Crédito mercantil", indent: true },
    { section: "Pasivos" },
    { key: "total_liabilities_net_minority_interest", label: "Pasivos totales", bold: true },
    { key: "total_current_liabilities", label: "Pasivo circulante", indent: true },
    { key: "short_term_debt", label: "Deuda de corto plazo", indent: true },
    { key: "long_term_debt", label: "Deuda de largo plazo", indent: true },
    { section: "Capital" },
    { key: "total_shareholder_equity", label: "Capital contable", bold: true },
    { key: "retained_earnings", label: "Utilidades retenidas", indent: true },
    { key: "ordinary_shares_number", label: "Acciones en circulación" }
  ].freeze

  CASH_FLOW_LINE_ITEMS = [
    { section: "Actividades de operación" },
    { key: "operating_cashflow", label: "Flujo de efectivo operativo", bold: true },
    { key: "net_income_from_continuing_operations", label: "Utilidad neta", indent: true },
    { key: "depreciation_and_amortization", label: "Depreciación y amortización", indent: true },
    { key: "change_in_working_capital", label: "Cambio en capital de trabajo", indent: true },
    { section: "Actividades de inversión" },
    { key: "investing_cash_flow", label: "Flujo de inversión", bold: true },
    { key: "capital_expenditures", label: "Inversión en activos fijos (CAPEX)", indent: true },
    { section: "Actividades de financiamiento" },
    { key: "financing_cash_flow", label: "Flujo de financiamiento", bold: true },
    { key: "dividend_payout", label: "Dividendos pagados", indent: true },
    { key: "repurchase_of_capital_stock", label: "Recompra de acciones", indent: true },
    { section: "Resumen" },
    { key: "changes_in_cash", label: "Cambio neto en efectivo", bold: true }
  ].freeze

  def line_items_for(statement_type)
    case statement_type.to_s
    when "income_statement" then INCOME_LINE_ITEMS
    when "balance_sheet"    then BALANCE_SHEET_LINE_ITEMS
    when "cash_flow"        then CASH_FLOW_LINE_ITEMS
    else INCOME_LINE_ITEMS
    end
  end

  def format_statement_value(value, currency:)
    return "—" if value.nil? || value.to_s == "None"

    format_large_currency(value.to_f, currency: currency)
  end
end
