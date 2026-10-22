module MarketData
  module Queries
    # ADR-031: one asset as plain data for a customer that must never hold a record,
    # built from the same domain objects the asset detail renders so the two cannot disagree.
    class AssetBrief
      HEADLINES = 3

      # @api public
      def self.call(symbol:)
        asset = AssetLookup.by_symbol(symbol)
        return nil unless asset

        {
          symbol: asset.symbol,
          name: asset.name,
          currency: asset.currency,
          quote: quote(asset),
          range_52w: range_52w(asset),
          reading: reading(asset.technical_reading),
          headlines: headlines(asset)
        }.freeze
      end

      def self.quote(asset)
        return nil if asset.current_price.nil?

        closes = PriceSeries.for(asset).latest(2).map(&:close)
        {
          price: asset.current_price,
          day_change_percent: Domain::DayChange.from_closes(closes),
          quoted_at: asset.price_updated_at,
          source: asset.data_source
        }
      end
      private_class_method :quote

      def self.range_52w(asset)
        fundamental, fallback = AssetFundamental.for_reading(asset)
        presenter = Domain::FundamentalPresenter.new(asset: asset, fundamental: fundamental, fallback: fallback)
        range = Domain::FiftyTwoWeekRange.for(
          price: asset.current_price,
          low: presenter.metric("fifty_two_week_low"),
          high: presenter.metric("fifty_two_week_high")
        )
        range && { low: range.low, high: range.high }
      end
      private_class_method :range_52w

      def self.reading(record)
        return nil if record.nil?

        { calculated_at: record.calculated_at, rows: Domain::IndicatorSignals.for(record) }
      end
      private_class_method :reading

      def self.headlines(asset)
        RecentNews.call(asset: asset).first(HEADLINES).map do |article|
          { title: article.title, source: article.source, published_at: article.published_at, url: article.url }
        end
      end
      private_class_method :headlines
    end
  end
end
