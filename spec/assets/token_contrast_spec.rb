require "rails_helper"

# The accent is the one brand colour too light to carry text and right as a
# fill, so text takes `primary-fg` and fills keep `primary` (#734, D56).
surfaces = %w[--color-bg-surface --color-bg-canvas --color-primary-muted]

RSpec.describe "app/assets/tailwind/application.css" do
  let(:css) { Rails.root.join("app/assets/tailwind/application.css").read }
  let(:light) { declared_colors(css.split(":where(html.dark)", 2).first) }
  let(:dark) { declared_colors(css.split(":where(html.dark)", 2).last) }

  def declared_colors(source)
    source.scan(/(--color-[\w-]+):\s*(#\h{6})\b/).to_h
  end

  def relative_luminance(hex)
    red, green, blue = hex.delete("#").scan(/../).map do |channel|
      value = channel.to_i(16) / 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  end

  def contrast(foreground, background)
    brighter, darker = [ relative_luminance(foreground), relative_luminance(background) ].minmax.reverse
    (brighter + 0.05) / (darker + 0.05)
  end

  { "light" => :light, "dark" => :dark }.each do |mode, palette|
    surfaces.each do |surface|
      it "sets accent text on #{surface.delete_prefix('--color-')} above the AA floor in #{mode}" do
        colors = send(palette)

        expect(contrast(colors.fetch("--color-primary-fg"), colors.fetch(surface))).to be >= 4.5
      end
    end
  end
end
