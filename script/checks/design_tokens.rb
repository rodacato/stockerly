# frozen_string_literal: true

require_relative "support"

module Checks
  # Colour comes from the Lumen tokens in app/assets/tailwind/application.css.
  # #489 counted 36 raw hex literals and 21 raw palette classes; #548 migrated
  # the opacity modifiers and added --color-focus. Nothing stopped the next view
  # from inlining #5B6CFF, and "the reviewer notices" is not a mechanism.
  #
  # Two surfaces are excluded by rule rather than by baseline, because in both
  # the literal is the correct answer: mail clients do not resolve CSS custom
  # properties, and the OS reads the PWA manifest and the theme-color meta as
  # literals.
  class DesignTokens < Check
    ID = "design-tokens"
    TITLE = "Colour comes from the Lumen tokens, not from a literal"

    SURFACES = [ "app/views/**/*.erb", "app/helpers/**/*.rb", "app/javascript/**/*.js" ].freeze
    EXCLUDED = %r{app/views/(pwa/|layouts/mailer|\w*mailer/)}
    HEX = /#(?:\h{8}|\h{6})\b/
    RGB = /\brgba?\(\s*\d/
    PALETTE = %w[
      slate gray zinc neutral stone red orange amber yellow lime green emerald
      teal cyan sky blue indigo violet purple fuchsia pink rose
    ].freeze
    PALETTE_CLASS = /\b(?:bg|text|border|ring|from|to|via|fill|stroke|divide|outline|accent|decoration|caret|placeholder|shadow)-(?:#{PALETTE.join('|')})-(?:50|\d{3})\b/

    def run
      paths = Checks.files(*SURFACES).grep_v(EXCLUDED)
      scan(paths) do |line|
        next if line.include?("theme-color")

        literal = line[HEX] || line[RGB] || line[PALETTE_CLASS]
        literal && "#{literal.strip} is a raw colour — use a Lumen token (app/assets/tailwind/application.css)"
      end
    end
  end
end
