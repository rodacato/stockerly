# frozen_string_literal: true

# Vendors the Material Symbols SVGs the app asks for into the rails_icons
# custom library. Re-run after adding a name to script/icon_names.txt.
#
# The gem's own sync cannot do this: Google nests each icon in its own
# directory (symbols/web/<name>/materialsymbolsoutlined/<name>_24px.svg) and
# the generator expects a flat one.

require "net/http"
require "fileutils"

NAMES  = File.readlines("script/icon_names.txt", chomp: true).reject(&:empty?).sort
TARGET = "app/assets/svg/icons/material_symbols"
BASE   = "https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web"

# Size belongs to the CSS that renders the icon, and colour to whatever text
# colour it sits in — so both are stripped from the file Google ships.
def normalize(svg)
  svg
    .sub(/\s*height="\d+"/, "")
    .sub(/\s*width="\d+"/, "")
    .sub("<svg ", %(<svg fill="currentColor" ))
    .strip
end

FileUtils.mkdir_p(TARGET)
missing = []

NAMES.each do |name|
  uri = URI("#{BASE}/#{name}/materialsymbolsoutlined/#{name}_24px.svg")
  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    File.write("#{TARGET}/#{name}.svg", normalize(response.body) + "\n")
    print "."
  else
    missing << name
    print "!"
  end
end

puts
puts "vendored #{NAMES.size - missing.size}/#{NAMES.size} into #{TARGET}"

unless missing.empty?
  warn "missing upstream: #{missing.join(', ')}"
  exit 1
end
