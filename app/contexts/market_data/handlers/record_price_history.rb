module MarketData
  module Handlers
    # Records daily OHLCV in AssetPriceHistory when a price update occurs.
    # Creates today's row or widens its high/low, and records which provider
    # produced the number.
    class RecordPriceHistory
      UNKNOWN_SOURCE = "unknown".freeze

      def self.call(event)
        new(event).call
      end

      def initialize(event)
        @event = event
      end

      def call
        today = Date.current
        existing = AssetPriceHistory.find_by(asset_id: asset_id, date: today, interval: "1d")

        existing ? widen(existing) : create(today)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        # Ignore race conditions on concurrent upserts
      end

      private

      attr_reader :event

      def widen(row)
        SourceChange.record(row, source) if row.source != source

        row.update!(
          close: new_price,
          high: [ row.high, new_price ].max,
          low: [ row.low, new_price ].min,
          source: source,
          as_of: as_of,
          fetched_at: Time.current
        )
      end

      def create(date)
        AssetPriceHistory.create!(
          asset_id: asset_id, date: date, interval: "1d", status: "confirmed",
          open: new_price, high: new_price, low: new_price, close: new_price,
          source: source, as_of: as_of, fetched_at: Time.current
        )
      end

      def asset_id
        field(:asset_id)
      end

      def new_price
        @new_price ||= field(:new_price).to_d
      end

      # A publisher that does not know its provider says so rather than having
      # one guessed for it; ADR-016 needs "we do not know" to stay legible.
      def source
        @source ||= field(:source).presence || UNKNOWN_SOURCE
      end

      def as_of
        field(:as_of).presence || Time.current
      end

      def field(name)
        return event[name] if event.is_a?(Hash)

        event.respond_to?(name) ? event.public_send(name) : nil
      end
    end
  end
end
