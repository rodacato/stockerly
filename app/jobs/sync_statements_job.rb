# Fetches all 3 financial statement types for 1 asset. Persists to
# FinancialStatement.
#
# Yahoo is the only source (D109, D123). Alpha Vantage's free tier refused
# BALANCE_SHEET as premium, and the provider is retired.
class SyncStatementsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  STATEMENT_KINDS = %w[income_statement balance_sheet cash_flow].freeze
  SOURCE = "yfinance".freeze

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return unless asset.asset_type_stock? || asset.asset_type_etf?

    gateway = MarketData::Gateways::YfinanceGateway.new
    synced_types = []

    STATEMENT_KINDS.each do |kind|
      result = GatewayChain.breaker_for(SOURCE).call { gateway.public_send(:"fetch_#{kind}", asset.symbol) }

      if result.success?
        persist_statements(asset, result.value!, kind)
        synced_types << kind
        log_sync_success("Statements: #{asset.symbol} (#{kind.upcase})")
      else
        tag, message = result.failure
        log_sync_failure("Statements: #{asset.symbol} (#{kind.upcase}) via #{SOURCE}", message,
          severity: tag == :rate_limited ? :warning : :error)
        break if tag == :rate_limited
      end
    end

    return if synced_types.empty?

    EventBus.publish(MarketData::Events::FinancialStatementsSynced.new(
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
        currency: report["reported_currency"] || asset.currency,
        source: SOURCE,
        fetched_at: Time.current
      )
    end
  end

  def quarter_for(date)
    ((date.month - 1) / 3) + 1
  end
end
