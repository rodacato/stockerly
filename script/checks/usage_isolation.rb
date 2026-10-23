# frozen_string_literal: true

require_relative "support"

module Checks
  # ADR-032 §8: outside its context the usage record is one door, Usage.record
  # (and Usage.opened for the day counters), so deleting it leaves the product whole.
  class UsageIsolation < Check
    ID = "usage-isolation"
    TITLE = "ADR-032: the usage record is reached only through Usage.record and Usage.opened"

    SCANNED = [ "app/**/*.{rb,erb,rake}", "lib/**/*.{rb,rake}", "config/**/*.rb" ].freeze

    DOORS = [
      "app/contexts/usage.rb",
      "app/contexts/usage/**",
      "app/models/usage_event.rb",
      "app/controllers/admin/usage_controller.rb",
      "app/controllers/usage_events_controller.rb",
      "app/views/admin/usage/**"
    ].freeze

    INTERNALS = /(?<![A-Za-z0-9_])(Usage::|UsageEvent\b)/

    def run
      paths = Checks.files(*SCANNED).reject { |path| DOORS.any? { |glob| File.fnmatch?(glob, path) } }
      scan(paths) do |line|
        "reaches into the usage record — call Usage.record or Usage.opened instead (ADR-032 §8)" if line.match?(INTERNALS)
      end
    end
  end
end
