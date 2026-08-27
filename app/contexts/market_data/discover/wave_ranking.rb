module MarketData
  module Discover
    # Ranks the baskets by what they did over the window, against the baseline
    # they are measured with (D31: `SPY` is the ruler, not a wave).
    #
    # A basket with fewer than two closes is dropped rather than shown at 0%:
    # "did not move" and "we have no data" are different statements, and only
    # one of them is true.
    class WaveRanking
      Wave = Data.define(:symbol, :name, :group, :change_percent, :vs_baseline, :closes, :referents)

      def self.call(bars:, baseline_symbol: BasketCatalogue.baseline, baskets: BasketCatalogue.all)
        baseline_change = change_for(bars[baseline_symbol])

        waves = baskets.filter_map do |basket|
          series = bars[basket.symbol]
          change = change_for(series)
          next if change.nil?

          Wave.new(symbol: basket.symbol, name: basket.name, group: basket.group,
                   change_percent: change,
                   vs_baseline: baseline_change ? (change - baseline_change).round(1) : nil,
                   closes: Array(series).map { |bar| bar[:close].to_f },
                   referents: basket.referents)
        end

        waves.sort_by { |wave| -wave.change_percent }
      end

      def self.change_for(series)
        closes = Array(series).map { |bar| bar[:close].to_f }
        return nil if closes.size < 2

        first = closes.first
        return nil unless first.positive?

        ((closes.last / first - 1) * 100).round(1)
      end
      private_class_method :change_for
    end
  end
end
