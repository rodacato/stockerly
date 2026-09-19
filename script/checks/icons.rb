# frozen_string_literal: true

require_relative "support"

module Checks
  # Icons are vendored SVGs rendered inline (ADR-0028), so a name nobody
  # vendored is a 500 at render time rather than a missing glyph.
  #
  # Two halves cover the two ways a name reaches the helper. rails_icons raises
  # on a miss, which the suite catches for names assembled at runtime; this
  # catches the literals without booting anything.
  class Icons < Check
    ID = "icons"
    TITLE = "Every icon the code names is vendored"

    LIBRARY = "app/assets/svg/icons/material_symbols"
    CALL = /icon_svg\s*\(*\s*"([a-z][a-z0-9_]*)"/
    ASSIGN = /\bicon:\s*"([a-z][a-z0-9_]*)"/

    def run
      seen = []

      violations = scan(Checks.files("app/**/*.erb", "app/**/*.rb", "config/**/*.rb", "lib/**/*.rb")) do |line|
        names = line.scan(CALL).flatten + line.scan(ASSIGN).flatten
        seen.concat(names)
        missing = names.reject { |name| vendored?(name) }
        next if missing.empty?

        "no vendored SVG for #{missing.join(', ')} — add the name to script/icon_names.txt, then run script/vendor_icons.rb"
      end

      seen.empty? ? [ extraction_broken ] : violations
    end

    private

    # Matching nothing passes every name, which is the one way this check can
    # lie. It reports itself instead.
    def extraction_broken
      Violation.new(
        path: "script/checks/icons.rb",
        line: 1,
        message: "matched no icon names at all — the patterns no longer describe how icons are called"
      )
    end

    def vendored?(name)
      File.exist?(File.join(ROOT, LIBRARY, "#{name}.svg"))
    end
  end
end
