# Syncs stock split data from FMP for assets with open positions.
# Publishes Trading::Events::SplitDetected for new splits to trigger position adjustment.
# Runs weekly to conserve FMP API budget.
class SyncSplitsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    gateway = MarketData::Gateways::FmpGateway.new
    detected = 0

    assets_with_open_positions.each do |asset|
      result = gateway.fetch_splits(asset.symbol)
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

  def assets_with_open_positions
    Asset.where(id: Position.open.select(:asset_id).distinct)
  end
end
