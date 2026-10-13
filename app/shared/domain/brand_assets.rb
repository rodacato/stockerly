# One number behind every brand-asset URL. The layout, the manifest and the
# service worker read it here so a logo change can't invalidate only two.
module BrandAssets
  VERSION = 6
  ROOT = File.expand_path("../../..", __dir__)

  def self.svg_body(name)
    File.read(File.join(ROOT, "design/brand/#{name}.svg"))[/<svg[^>]*>(.*)<\/svg>/m, 1]
  end

  def self.palette(mode = :light)
    css = File.read(File.join(ROOT, "app/assets/tailwind/application.css"))
    light, dark = css.split(":where(html.dark)", 2)
    source = mode.to_sym == :dark ? dark : light
    source.scan(/--color-([\w-]+):\s*(#\h{6})\b/).to_h
  end

  def self.color(role, mode = :light)
    palette(mode).fetch(role)
  end
end
