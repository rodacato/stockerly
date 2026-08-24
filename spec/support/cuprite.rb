require "capybara/cuprite"

# Only specs that genuinely depend on JS opt in, with `type: :system, js: true`.
# Everything else stays on rack_test — converting the ~40 existing system specs
# would cost minutes per run to prove what they already prove.
#
# The options go through Rails' own `driven_by`, which has native cuprite
# support and *overrides* any Capybara.register_driver(:cuprite) we write — such
# a registration is ignored in silence, browser_path and all. It also mutates
# the hash it is handed, so this hands it a fresh one each time.
# The devcontainer has chromium; CI runners ship google-chrome. Falling through
# to nil lets ferrum autodetect rather than fail on a hardcoded path.
def chrome_path
  ENV["CHROME_PATH"].presence ||
    %w[/usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome].find { |path| File.executable?(path) }
end

def cuprite_options
  {
    browser_path: chrome_path,
    browser_options: { "no-sandbox": nil, "disable-dev-shm-usage": nil, "disable-gpu": nil },
    process_timeout: 30,
    timeout: 15,
    headless: true
  }
end

RSpec.configure do |config|
  # 390x844 is the design's base frame (D7), so a JS spec sees the mobile layout
  # the sheet was drawn for.
  config.before(:each, type: :system, js: true) do
    driven_by :cuprite, screen_size: [ 390, 844 ], options: cuprite_options
  end
end
