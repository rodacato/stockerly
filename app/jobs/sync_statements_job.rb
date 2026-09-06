# Fetches all 3 financial statement types for 1 asset. Persists to
# FinancialStatement.
#
# D109: yfinance leads and Alpha Vantage falls back. Alpha Vantage's free tier
# refuses BALANCE_SHEET as a premium endpoint, so a third of every sync was a
# call that could not succeed — one that still cost a slot against the 25/day
# budget and opened the circuit breaker on the two that do work. Yahoo answers
# all three for free and returns five annual periods rather than a snapshot.
class SyncStatementsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  STATEMENT_KINDS = %w[income_statement balance_sheet cash_flow].freeze
  # Order is priority. `source` is stamped on every row, so a table holding
  # both providers still says which one wrote each period.
  SOURCES = {
    "yfinance" => -> { MarketData::Gateways::YfinanceGateway.new },
    "alpha_vantage" => -> { MarketData::Gateways::AlphaVantageGateway.new }
  }.freeze

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return unless asset.asset_type_stock? || asset.asset_type_etf?

    synced_types = []

    STATEMENT_KINDS.each do |kind|
      answer, failures = fetch(kind, asset.symbol)

      if answer
        persist_statements(asset, answer[:data], kind, answer[:source])
        synced_types << kind
        log_sync_success("Statements: #{asset.symbol} (#{kind.upcase})")
      else
        break if log_failures(asset, kind, failures) == :rate_limited
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

  # The first source that answers wins. A provider whose key is not configured
  # is skipped rather than raising: a self-hosted instance with no Alpha Vantage
  # key still gets all three statements from Yahoo.
  def fetch(kind, symbol)
    failures = []

    SOURCES.each do |source, build|
      gateway = begin
        build.call
      rescue MarketData::Gateways::ApiKeyNotConfiguredError
        next
      end

      result = GatewayChain.breaker_for(source).call { gateway.public_send(:"fetch_#{kind}", symbol) }
      return [ { data: result.value!, source: source }, failures ] if result.success?

      failures << [ source, result.failure ]
    end

    [ nil, failures ]
  end

  # One line per source that was tried, so "Yahoo had nothing" and "Alpha
  # Vantage wants money for it" stay distinguishable in the log.
  def log_failures(asset, kind, failures)
    failures.each do |source, failure|
      log_sync_failure("Statements: #{asset.symbol} (#{kind.upcase}) via #{source}", failure[1],
        severity: failure[0] == :rate_limited ? :warning : :error)
    end

    :rate_limited if failures.any? { |_, failure| failure[0] == :rate_limited }
  end

  def persist_statements(asset, data, statement_type, source)
    persist_reports(asset, data[:annual_reports], statement_type, "annual", source)
    persist_reports(asset, data[:quarterly_reports], statement_type, "quarterly", source)
  end

  def persist_reports(asset, reports, statement_type, period_type, source)
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
        source: source,
        fetched_at: Time.current
      )
    end
  end

  def quarter_for(date)
    ((date.month - 1) / 3) + 1
  end
end
