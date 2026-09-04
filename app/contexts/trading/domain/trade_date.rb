module Trading
  module Domain
    # What a trade's executed_at may be: something the clock can read, and not
    # a date that has not happened. Three contracts ask it — the sheet's two
    # and the importer's — and each phrases the refusal for its own reader.
    module TradeDate
      module_function

      # nil when the date is usable, :invalid or :future otherwise.
      def fault(value)
        parsed = parse(value)
        return :invalid if parsed.nil?

        :future if parsed.to_date > Date.current
      end

      # Time.zone, not Date: it is what ExecuteTrade and UpdateTrade persist
      # with, so the guard and the write read the same string the same way.
      def parse(value)
        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
