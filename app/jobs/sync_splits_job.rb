# Syncs splits for assets with open positions, from whichever source serves the
# asset's market: Alpaca for US, the yfinance bridge for the BMV (#312).
# Publishes Trading::Events::SplitDetected so positions are adjusted.
class SyncSplitsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    detected = 0

    assets_with_open_positions.each do |asset|
      result = chain_for(asset).fetch_splits(asset.gateway_symbols)
      next if result.failure?

      result.value!.each do |data|
        split = asset.stock_splits.find_or_initialize_by(ex_date: data[:date])
        next unless split.new_record?

        split.assign_attributes(
          ratio_from: data[:denominator],
          ratio_to: data[:numerator]
        )

        next unless split.save

        EventBus.publish(Trading::Events::SplitDetected.new(
          asset_id: asset.id,
          stock_split_id: split.id,
          ratio_from: split.ratio_from,
          ratio_to: split.ratio_to
        ))
        detected += 1
      end
    end

    log_sync_success("Splits Sync", message: "#{detected} new splits detected")
  end

  private

  def chain_for(asset)
    GatewayChain.for_capability(:splits, market: asset.market, asset_type: asset.asset_type)
  end

  def assets_with_open_positions
    Asset.where(id: Position.open.select(:asset_id).distinct)
  end
end
