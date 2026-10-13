require "rails_helper"

RSpec.describe BrandAssets do
  def luminance(hex)
    channels = hex.delete_prefix("#").scan(/../).map { |value| value.to_i(16) / 255.0 }
    linear = channels.map { |value| value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4 }
    linear.zip([ 0.2126, 0.7152, 0.0722 ]).sum { |value, weight| value * weight }
  end

  it "keeps reading, button and status label pairs above WCAG AA in both modes" do
    pairs = [ [ "fg-inverse", "primary-fg" ], [ "positive-fg", "positive-bg" ],
              [ "negative-fg", "negative-bg" ], [ "warning-fg", "warning-bg" ] ]
    pairs += %w[bg-canvas bg-surface bg-muted].map { |surface| [ "fg-subtle", surface ] }
    %i[light dark].each do |mode|
      pairs.each do |foreground, background|
        low, high = [ foreground, background ].map { |role| luminance(described_class.color(role, mode)) }.sort
        expect((high + 0.05) / (low + 0.05)).to be >= 4.5, "#{mode}: #{foreground} on #{background}"
      end
    end
  end
end
