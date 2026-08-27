module MarketData
  module Discover
    # Read API: the Banxico and Fed dates the Descubrir calendar renders.
    #
    # Backed by a hand-maintained YAML rather than a gateway (D33) and by no
    # table at all, which is D31's disposability contract. `exhausted?` is the
    # state that decision left open: past the file's horizon the screen says so
    # instead of rendering nothing.
    class PolicyCalendar
      Event = Data.define(:date, :source, :title, :tentative)

      PATH = Rails.root.join("config", "discover_calendar.yml")

      class << self
        def upcoming(limit: 3, today: Date.current)
          events.select { |event| event.date >= today }.first(limit)
        end

        def exhausted?(today: Date.current)
          upcoming(limit: 1, today: today).empty?
        end

        def horizon
          data["horizon"]
        end

        def source_urls
          data["sources"] || {}
        end

        def reload!
          @data = nil
        end

        private

        def events
          (data["events"] || []).map do |row|
            Event.new(date: row["date"].to_date, source: row["source"],
                      title: row["title"], tentative: row["tentative"] || false)
          end.sort_by(&:date)
        end

        def data
          @data ||= YAML.safe_load_file(PATH, permitted_classes: [ Date ]) || {}
        end
      end
    end
  end
end
