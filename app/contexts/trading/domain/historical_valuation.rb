module Trading
  module Domain
    # What the portfolio was worth on a past date, derived from the trades
    # rather than read from a snapshot. Loads each collection once and answers
    # per-date from memory, because a rebuild asks about hundreds of days.
    class HistoricalValuation
      def initialize(portfolio, currency:)
        @portfolio = portfolio
        @currency  = currency
        @trades    = portfolio.trades.kept.includes(:asset).order(:executed_at).to_a
        @closes    = {}
        @splits    = {}
      end

      def market_value_on(date)
        shares_on(date).sum { |asset, shares| value_of(asset, shares, date) }
      end

      # Shares held at the end of `date`. SplitAdjuster rewrites past trades
      # into post-split terms, so these are directly comparable to
      # Position#shares — and to the adjusted close below.
      def shares_on(date)
        cutoff = date.end_of_day
        held = Hash.new(0)

        @trades.each do |trade|
          break if trade.executed_at > cutoff

          held[trade.asset] += trade.side == "sell" ? -trade.shares : trade.shares
        end

        held.select { |_, shares| shares.positive? }
      end

      private

      def value_of(asset, shares, date)
        close = adjusted_close(asset, date)
        return 0 if close.nil?

        @portfolio.convert(shares * close, from: asset.currency, to: @currency, at_date: date)
      end

      # The stored close is in the terms of its own day, while the shares above
      # are post-split. A 1:2 split doubles shares and halves price, so valuing
      # post-split shares at a pre-split close doubles the answer. Dividing by
      # the ratio of every split since `date` puts both on the same footing.
      def adjusted_close(asset, date)
        close = close_on(asset, date)
        return nil if close.nil?

        close / split_ratio_since(asset, date)
      end

      # Splits compose by multiplication: two 1:2 splits quadruple the shares.
      def split_ratio_since(asset, date)
        splits_for(asset)
          .select { |split| split.ex_date > date }
          .reduce(1.0) { |ratio, split| ratio * split.ratio }
      end

      # Markets close on weekends and holidays, so an exact-date lookup finds
      # nothing on a Saturday. Same rule FxRateHistory.rate_on already applies.
      def close_on(asset, date)
        history(asset).reverse_each.find { |row| row.date <= date }&.close
      end

      def history(asset)
        @closes[asset.id] ||= MarketData::Queries::PriceSeries.for(asset).all.to_a
      end

      def splits_for(asset)
        @splits[asset.id] ||= asset.stock_splits.to_a
      end
    end
  end
end
