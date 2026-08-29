# iOS draws a blank screen on launch unless it finds a startup image whose
# media query matches the device exactly, so every size needs its own link.
module IosSplash
  Device = Data.define(:css_width, :css_height, :ratio)

  DEVICES = [
    [ 430, 932, 3 ], [ 428, 926, 3 ], [ 402, 874, 3 ], [ 393, 852, 3 ],
    [ 390, 844, 3 ], [ 375, 812, 3 ], [ 414, 896, 2 ], [ 375, 667, 2 ]
  ].map { |dims| Device.new(*dims) }.freeze

  SCHEMES = %w[light dark].freeze

  def self.each_image
    return to_enum(:each_image) unless block_given?

    DEVICES.each do |device|
      SCHEMES.each do |scheme|
        yield device, scheme, "/splash/splash-#{device.css_width}x#{device.css_height}@#{device.ratio}-#{scheme}.png"
      end
    end
  end

  def self.media_query(device, scheme)
    "(prefers-color-scheme: #{scheme}) and (device-width: #{device.css_width}px) and " \
      "(device-height: #{device.css_height}px) and (-webkit-device-pixel-ratio: #{device.ratio}) and " \
      "(orientation: portrait)"
  end
end
