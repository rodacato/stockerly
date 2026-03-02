# Fetches all 3 financial statement types for 1 asset (3 API calls).
# Triggered by SyncAllStatementsJob. Persists to FinancialStatement model.
class SyncStatementsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  STATEMENT_TYPES = %w[INCOME_STATEMENT BALANCE_SHEET CASH_FLOW].freeze
  TYPE_MAP = {
    "INCOME_STATEMENT" => "income_statement",
    "BALANCE_SHEET"    => "balance_sheet",
    "CASH_FLOW"        => "cash_flow"
  }.freeze

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return unless asset.asset_type_stock? || asset.asset_type_etf?

    gateway = MarketData::AlphaVantageGateway.new
    synced_types = []

    STATEMENT_TYPES.each do |function|
      method_name = :"fetch_#{TYPE_MAP[function]}"
      result = breaker.call { gateway.send(method_name, asset.symbol) }

      if result.success?
        persist_statements(asset, result.value!, TYPE_MAP[function])
        synced_types << TYPE_MAP[function]
        log_sync_success("Fundamentals: #{asset.symbol}")
      else
        log_sync_failure("Statements: #{asset.symbol} (#{function})", result.failure[1],
          severity: result.failure[0] == :rate_limited ? :warning : :error)
        break if result.failure[0] == :rate_limited
      end
    end

    return if synced_types.empty?

    EventBus.publish(MarketData::FinancialStatementsSynced.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      statement_types: synced_types
    ))
  end

  private

  def persist_statements(asset, data, statement_type)
    persist_reports(asset, data[:annual_reports], statement_type, "annual")
    persist_reports(asset, data[:quarterly_reports], statement_type, "quarterly")
  end

  def persist_reports(asset, reports, statement_type, period_type)
    reports.each do |report|
      fiscal_date = Date.parse(report["fiscal_date_ending"])
      stmt = FinancialStatement.find_or_initialize_by(
        asset: asset,
        statement_type: statement_type,
        period_type: period_type,
        fiscal_date_ending: fiscal_date
      )
      stmt.update!(
        data: report,
        fiscal_year: fiscal_date.year,
        fiscal_quarter: period_type == "quarterly" ? quarter_for(fiscal_date) : nil,
        currency: report["reported_currency"] || "USD",
        source: "alpha_vantage",
        fetched_at: Time.current
      )
    end
  end

  def quarter_for(date)
    ((date.month - 1) / 3) + 1
  end

  def breaker
    SyncSingleAssetJob.circuit_breaker_for("alpha_vantage")
  end
end
