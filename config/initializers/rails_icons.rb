# frozen_string_literal: true

# Icons are vendored SVGs under app/assets/svg/icons/material_symbols and
# rendered inline, so a glyph cannot fail to arrive separately from its page.
# script/vendor_icons.rb refreshes them; ADR-0028 has the reasoning.
RailsIcons.configure do |config|
  config.default_library = "material_symbols"
end
