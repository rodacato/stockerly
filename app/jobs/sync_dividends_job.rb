# Syncs dividends for assets with open positions, from whichever source serves
# the asset's market: Alpaca for US, the yfinance bridge for the BMV (#312).
class SyncDividendsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    asset_count = 0
    dividend_count = 0

    assets_with_open_positions.each do |asset|
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

  def assets_with_open_positions
    Asset.where(id: Position.open.select(:asset_id).distinct)
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

  def create_payments(dividend)
    positions = Position.open.where(asset: dividend.asset).includes(:portfolio)

    positions.find_each do |position|
      DividendPayment.find_or_create_by!(
        portfolio: position.portfolio,
        dividend: dividend
      ) do |payment|
        payment.shares_held = position.shares
        payment.total_amount = position.shares * dividend.amount_per_share
      end
    rescue ActiveRecord::RecordNotUnique
      next
    end
  end
end
