# Syncs dividends for the assets a portfolio has held recently, from whichever
# source serves the asset's market: Alpaca for US, the yfinance bridge for the
# BMV (#312).
class SyncDividendsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    asset_count = 0
    dividend_count = 0

    assets_to_check.each do |asset|
      result = chain_for(asset).fetch_dividends(asset.gateway_symbols)
      next if result.failure?

      synced = sync_dividends_for(asset, result.value!)
      if synced > 0
        asset_count += 1
        dividend_count += synced
      end
    end

    EventBus.publish(MarketData::Events::DividendsSynced.new(
      asset_count: asset_count,
      dividend_count: dividend_count
    ))

    log_sync_success("Dividends Sync", message: "#{dividend_count} dividends across #{asset_count} assets")
  end

  private

  def chain_for(asset)
    GatewayChain.for_capability(:dividends, market: asset.market, asset_type: asset.asset_type)
  end

  # Open positions, plus the ones closed recently: a dividend is declared and
  # paid weeks after its ex-date, and selling does not undo an entitlement
  # already earned. The window keeps the list from growing forever, which is
  # what asking about every asset ever held would do to the call budget.
  RECENTLY_CLOSED = 90.days

  def assets_to_check
    recently_closed = Position.where(status: :closed)
                              .where(closed_at: RECENTLY_CLOSED.ago..)
                              .select(:asset_id)

    Asset.where(id: Position.open.select(:asset_id)).or(Asset.where(id: recently_closed)).distinct
  end

  def sync_dividends_for(asset, dividend_data)
    synced = 0

    dividend_data.each do |data|
      dividend = asset.dividends.find_or_initialize_by(ex_date: data[:ex_date])
      dividend.assign_attributes(
        amount_per_share: data[:amount_per_share],
        pay_date: data[:pay_date],
        currency: data[:currency] || "USD"
      )

      next unless dividend.new_record? || dividend.changed?

      dividend.save!
      create_payments(dividend) if dividend.previously_new_record?
      synced += 1
    rescue ActiveRecord::RecordInvalid
      next
    end

    synced
  end

  # Entitlement is settled on the ex-date: whoever held the shares that day is
  # paid, whether or not they still hold them now. Reading the open position
  # instead got both directions wrong — it credited shares bought after the
  # ex-date, and paid nothing at all to a position since closed.
  def create_payments(dividend)
    portfolios_trading_before(dividend).find_each do |portfolio|
      shares = portfolio.shares_held_on(dividend.asset, dividend.ex_date)
      next unless shares.positive?

      DividendPayment.find_or_create_by!(
        portfolio: portfolio,
        dividend: dividend
      ) do |payment|
        payment.shares_held = shares
        payment.total_amount = shares * dividend.amount_per_share
      end
    rescue ActiveRecord::RecordNotUnique
      next
    end
  end

  def portfolios_trading_before(dividend)
    Portfolio.where(id: Trade.kept
                            .where(asset: dividend.asset)
                            .where(executed_at: ..dividend.ex_date.end_of_day)
                            .select(:portfolio_id))
  end
end
