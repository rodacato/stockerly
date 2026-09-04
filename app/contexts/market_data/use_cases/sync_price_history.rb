module MarketData
  module UseCases
    # Fetches a range of daily bars for one asset and writes them with the
    # provenance ADR-016 requires.
    #
    # It exists because two callers need the same thing over different ranges:
    # BackfillPriceHistoryJob takes every new asset through a fixed window, and
    # `data:deepen` reaches further back on request. Routing and writing lived
    # in the job, so the second caller could only have them by copying them.
    class SyncPriceHistory < ApplicationUseCase
      INTERVAL = "1d".freeze

      # `overwrite: false` is what makes deepening safe to re-run: it adds the
      # dates an asset lacks and can never restate the ones it holds.
      def call(asset:, from:, to: Date.current, overwrite: true)
        sources = DataSourceRegistry.for_capability(:historical, market: asset.market, asset_type: asset.asset_type)
        return Failure([ :not_supported, "No historical source for #{asset.market}/#{asset.asset_type}" ]) if sources.empty?

        source, bars = yield fetch(sources, asset, from, to)
        written, rejected = store(asset, bars, source, overwrite)

        Success(source: source, fetched: bars.size, written: written, rejected: rejected)
      end

      private

      # The winning provider is not knowable from the call site, so it is
      # returned rather than inferred.
      def fetch(sources, asset, from, to)
        last = nil

        sources.each do |source|
          klass = source.gateway_class
          result = attempt(klass, asset, from, to)
          next if result.nil?

          last = result
          return Success([ klass.source_id, result.value! ]) if result.success?
        end

        last&.failure ? Failure(last.failure) : Failure([ :not_configured, "No configured source for #{asset.symbol}" ])
      end

      # An unconfigured provider is skipped rather than raised, so a missing key
      # degrades to the next source instead of failing the call outright.
      def attempt(klass, asset, from, to)
        klass.new.fetch_historical(symbol_for(klass, asset), reachable_from(klass, from, to), to)
      rescue MarketData::Gateways::ApiKeyNotConfiguredError
        nil
      end

      # Ask each provider only as far back as it serves. One caller's range
      # cannot be right for all of them: the same request that gets ten years
      # from Alpaca gets a 401 and no crypto at all from CoinGecko (D71).
      def reachable_from(klass, from, to)
        limit = klass.max_history_days
        return from if limit.nil?

        [ from, to - limit.days ].max
      end

      # The BMV addresses an issuer differently from Yahoo, and the asset
      # carries the mapping already.
      def symbol_for(klass, asset)
        return asset.symbol unless klass.const_defined?(:PROVIDER)

        asset.symbol_for(klass::PROVIDER)
      end

      def store(asset, bars, source, overwrite)
        bars = reject_known(asset, bars) unless overwrite
        written = 0
        rejected = 0

        bars.each do |bar|
          write(asset, bar, source)
          written += 1
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          rejected += 1
        end

        [ written, rejected ]
      end

      def reject_known(asset, bars)
        known = asset.asset_price_histories.where(interval: INTERVAL).pluck(:date).to_set
        bars.uniq { |bar| bar[:date] }.reject { |bar| known.include?(bar[:date]) }
      end

      # DataBursatil reports a close and nothing else, so a bar carries only what
      # its provider had — assigning the rest would blank what another source
      # filled.
      def write(asset, bar, source)
        AssetPriceHistory.find_or_initialize_by(asset_id: asset.id, date: bar[:date], interval: INTERVAL).tap do |record|
          SourceChange.record(record, source) if record.persisted?

          record.assign_attributes(bar.slice(:open, :high, :low, :close, :volume).compact)
          record.assign_attributes(
            source: source,
            status: "confirmed",
            as_of: bar[:date].end_of_day,
            fetched_at: Time.current
          )
          record.save!
        end
      end
    end
  end
end
