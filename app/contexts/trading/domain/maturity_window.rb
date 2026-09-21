module Trading
  module Domain
    # How near a fixed-income lot has to be to its maturity for the days left to
    # be what the row reports. Further out it is a date on the detail screen,
    # not the number that displaces a day change (D69).
    class MaturityWindow
      DAYS = 30

      def self.days_until(position)
        date = position.maturity_date
        return nil if date.blank?

        days = (date - Date.current).to_i
        days if days.between?(0, DAYS)
      end
    end
  end
end
