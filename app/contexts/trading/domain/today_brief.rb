module Trading
  module Domain
    # What the daily view says before it shows anything: a first run, quotes it
    # cannot vouch for, a short list of things worth a look, or that nothing is.
    # "Nothing" is only ever claimed over quotes it can vouch for (ADR-023).
    class TodayBrief
      LIMIT = 3
      NEAR_TARGET_PERCENT = 5.0
      PRIORITY = { maturity: 0, earnings: 1, macro: 2, contribution: 3, allocation: 4, target: 5 }.freeze
      # What a quote has to be current for: a distance to a price, a share of the patrimonio.
      PRICE_DEPENDENT = %i[allocation target].freeze

      Item = Data.define(:kind, :asset, :days, :date, :gap, :subject, :actual, :target, :label, :tentative) do
        def initialize(kind:, asset: nil, days: nil, date: nil, gap: nil, subject: nil, actual: nil, target: nil, label: nil, tentative: false) = super

        # Nearest first; for a share off its plan, the widest gap first.
        def rank
          case kind
          when :allocation then -gap.abs
          when :contribution then 0
          else days || gap
          end
        end
      end
      Result = Data.define(:state, :items, :total)

      def self.call(tracks_anything:, quotes_reliable:, candidates:)
        return Result.new(:first_run, [], 0) unless tracks_anything

        usable = quotes_reliable ? candidates : candidates.reject { |item| PRICE_DEPENDENT.include?(item.kind) }
        ranked = usable.sort_by { |item| [ PRIORITY.fetch(item.kind), item.rank ] }

        Result.new(state_for(quotes_reliable, ranked), ranked.first(LIMIT), ranked.size)
      end

      def self.state_for(quotes_reliable, ranked)
        return :stale unless quotes_reliable

        ranked.empty? ? :calm : :items
      end
      private_class_method :state_for
    end
  end
end
