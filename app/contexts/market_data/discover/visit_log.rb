module MarketData
  module Discover
    # The evidence D31's kill criterion asks for: *"eight weeks after merge, if
    # it was not opened in at least 4 of those 8 weeks, it is deleted."*
    #
    # A single `last_seen` cannot answer that — it says when, never how often —
    # so the weeks themselves are recorded. Still no table: this is the same
    # cache the screen already lives in, and it is deleted with the rest.
    class VisitLog
      WEEKS_KEY = "discover:weeks_seen".freeze
      LAST_SEEN_KEY = "discover:last_seen".freeze
      WINDOW = 8
      # Twice the window, so the number stays honest right after a gap instead
      # of forgetting the weeks it is being judged on.
      KEPT = WINDOW * 2
      RETENTION = 1.year

      class << self
        def record(now: Time.current)
          Rails.cache.write(LAST_SEEN_KEY, now, expires_in: RETENTION)

          week = week_key(now)
          weeks = recorded_weeks
          return if weeks.include?(week)

          Rails.cache.write(WEEKS_KEY, (weeks + [ week ]).last(KEPT), expires_in: RETENTION)
        end

        def last_seen
          Rails.cache.read(LAST_SEEN_KEY)
        end

        # How many of the last `window` calendar weeks the screen was opened in.
        def weeks_seen(window: WINDOW, now: Time.current)
          recent = (0...window).map { |back| week_key(now - back.weeks) }

          (recorded_weeks & recent).size
        end

        def window = WINDOW

        private

        def recorded_weeks
          Array(Rails.cache.read(WEEKS_KEY))
        end

        # ISO week, so a year boundary does not collapse two different weeks
        # onto the same key.
        def week_key(moment)
          moment.strftime("%G-W%V")
        end
      end
    end
  end
end
