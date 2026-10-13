require "rails_helper"

RSpec.describe "Lumen financial surfaces", type: :system, js: true do
  let!(:user) { create(:user, email: "brand-surface@example.test", password: "password123", preferred_currency: "MXN", onboarded_at: Time.current) }
  let!(:asset) { create(:asset, :mexican, symbol: "DEMO", name: "Synthetic demonstration asset", current_price: 123.45, price_updated_at: Time.current, data_source: "Synthetic") }

  before do
    portfolio = user.portfolio || create(:portfolio, user: user)
    portfolio.update!(inception_date: 10.days.ago.to_date)
    position = create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 100)
    create(:trade, portfolio: portfolio, position: position, asset: asset, shares: 100, price_per_share: 100, executed_at: 10.days.ago, currency: "MXN")
    7.downto(0) do |day|
      create(:asset_price_history, asset: asset, date: day.days.ago.to_date, close: 123.45 - day, source: "Synthetic")
      create(:portfolio_snapshot, portfolio: portfolio, date: day.days.ago.to_date, currency: "MXN", total_value: 12345 - (day * 100))
    end
    visit login_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "keeps the financial routes within the viewport in both modes" do
    directory = Rails.root.join("tmp/brand-review/final")
    [ 1280, 320 ].each do |width|
      page.current_window.resize_to(width, 900)
      [ dashboard_path, portfolio_path, assets_path, market_asset_path(asset.symbol) ].each do |route|
        visit route
        expect(page).to have_css("main")
        [ false, true ].each do |dark|
          page.execute_script("document.documentElement.classList.toggle('dark', #{dark})")
          page.evaluate_async_script(<<~JS)
            const done = arguments[0];
            requestAnimationFrame(() => requestAnimationFrame(() => {
              const finite = document.getAnimations().filter(animation => animation.effect.getComputedTiming().iterations !== Infinity);
              Promise.all(finite.map(animation => animation.finished.catch(() => {}))).then(() => done(true));
            }));
          JS
          expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), "#{route} at #{width}px, dark=#{dark}"
          if ENV["BRAND_VISUAL_EVIDENCE"] == "1"
            FileUtils.mkdir_p(directory)
            page.driver.browser.screenshot(path: directory.join("#{route.tr('/', '-')}-#{width}-#{dark ? 'dark' : 'light'}.png").to_s, full: true)
          end
        end
        if route == market_asset_path(asset.symbol)
          click_button I18n.t("posicion.tab_posicion")
          expect(page).to have_text("MXN 10,000.00")
          expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
          if ENV["BRAND_VISUAL_EVIDENCE"] == "1"
            page.driver.browser.screenshot(path: directory.join("position-#{width}-dark.png").to_s, full: true)
          end
        end
      end
    end
  end

  it "supports position tabs by keyboard and exposes visible focus" do
    visit market_asset_path(asset.symbol)
    find("#position-tab-0").send_keys(:right)
    expect(page).to have_css("#position-tab-1[aria-selected='true']:focus")
    expect(page).to have_css("#position-panel-1:not(.hidden)")
    expect(page.evaluate_script("getComputedStyle(document.activeElement).outlineWidth")).to eq("2px")
    find("#position-tab-1").send_keys(:home)
    expect(page).to have_css("#position-tab-0[aria-selected='true']:focus")
  end

  it "honors the browser's reduced-motion preference" do
    page.driver.browser.page.command("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    visit dashboard_path
    expect(page.evaluate_script("matchMedia('(prefers-reduced-motion: reduce)').matches")).to be(true)
    expect(page.evaluate_script("getComputedStyle(document.querySelector('a')).transitionDuration")).to eq("1e-05s")
  ensure
    page.driver.browser.page.command("Emulation.setEmulatedMedia", features: [])
  end

  it "uses the installed service worker's fallback without caching portfolio HTML" do
    expect(page).to have_css("main")
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      navigator.serviceWorker.ready.then(() => navigator.serviceWorker.controller ? true :
        new Promise(resolve => navigator.serviceWorker.addEventListener('controllerchange', () => resolve(true), { once: true })))
        .then(done);
    JS
    expect(page.evaluate_script("Boolean(navigator.serviceWorker.controller)")).to be(true)
    visit portfolio_path
    cached_paths = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      caches.keys().then(keys => Promise.all(keys.map(key => caches.open(key).then(cache => cache.keys()))))
        .then(groups => groups.flat().map(request => new URL(request.url).pathname)).then(done);
    JS
    expect(cached_paths).to include("/offline.html")
    expect(cached_paths).not_to include("/dashboard", "/portfolio", "/assets")
    page.driver.browser.page.command("Network.emulateNetworkConditions", offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0)
    visit dashboard_path
    expect(page).to have_text("Patrimonio no disponible sin red")
    expect(page).to have_link("Volver a intentar", href: dashboard_path)
  ensure
    page.driver.browser.page.command("Network.emulateNetworkConditions", offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1)
  end
end
