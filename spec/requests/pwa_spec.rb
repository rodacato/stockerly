require "rails_helper"

RSpec.describe "PWA", type: :request do
  # The cache bust lives in the layout, the manifest and the service worker.
  # These specs pin the three to each other rather than to a literal, so a
  # brand bump that misses one fails here instead of serving a stale logo.
  def cache_bust_version
    get login_path
    response.body[%r{/manifest\.json\?v=(\d+)}, 1]
  end

  describe "manifest.json" do
    it "serves valid manifest with correct metadata" do
      get "/manifest.json"

      expect(response).to have_http_status(:ok)
      manifest = JSON.parse(response.body)
      expect(manifest["short_name"]).to eq("Stockerly")
      expect(manifest["start_url"]).to eq("/dashboard")
      expect(manifest["display"]).to eq("standalone")
      expect(manifest["theme_color"]).to eq("#5B6CFF")
      expect(manifest["icons"].size).to be >= 2
    end

    it "carries an id so identity survives a start_url change" do
      get "/manifest.json"

      expect(JSON.parse(response.body)["id"]).to be_present
    end

    it "declares a maskable icon drawn separately from the plain one" do
      get "/manifest.json"
      icons = JSON.parse(response.body)["icons"]

      maskable, plain = icons.partition { |icon| icon["purpose"].to_s.include?("maskable") }
      expect(maskable).not_to be_empty
      expect(plain.map { |icon| icon["src"] }).not_to include(*maskable.map { |icon| icon["src"] })
    end

    # Android mints the home-screen icon from a raster source; an SVG-only
    # maskable entry silently falls back to the plain icon in a white circle.
    it "offers the maskable and monochrome icons as PNG, which Android requires" do
      get "/manifest.json"
      icons = JSON.parse(response.body)["icons"]

      %w[maskable monochrome].each do |purpose|
        matching = icons.select { |icon| icon["purpose"] == purpose }
        expect(matching).not_to be_empty
        expect(matching.map { |icon| icon["type"] }).to all(eq("image/png"))
      end
    end

    it "points every shortcut at a route that resolves" do
      get "/manifest.json"
      shortcuts = JSON.parse(response.body)["shortcuts"]

      expect(shortcuts).not_to be_empty
      shortcuts.each do |shortcut|
        expect(shortcut["name"]).to be_present
        expect { Rails.application.routes.recognize_path(shortcut["url"]) }.not_to raise_error
      end
    end

    it "is revalidated on every load instead of inheriting the one-year asset cache" do
      get "/manifest.json"

      expect(response.headers["cache-control"]).to include("must-revalidate")
    end
  end

  describe "service-worker.js" do
    it "serves the service worker script" do
      get "/service-worker.js"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CACHE_VERSION")
      expect(response.body).to include("stockerly-static")
    end

    # A far-future max-age here is what stranded production on a worker from
    # six days before the brand bump: the edge kept answering with the old file.
    it "is revalidated on every load instead of inheriting the one-year asset cache" do
      get "/service-worker.js"

      expect(response.headers["cache-control"]).to include("must-revalidate")
    end

    it "handles the push events an alert needs to reach a closed app" do
      get "/service-worker.js"

      expect(response.body).to include('addEventListener("push"')
      expect(response.body).to include('addEventListener("notificationclick"')
      expect(response.body).to include("setAppBadge")
    end

    it "includes font cache for Google Fonts" do
      get "/service-worker.js"

      expect(response.body).to include("stockerly-fonts")
      expect(response.body).to include("fonts.googleapis.com")
    end

    it "pre-caches offline page and icons" do
      version = cache_bust_version

      get "/service-worker.js"

      expect(response.body).to include("/offline.html")
      %w[/favicon.svg /icon-192.png /icon-512.png /icon-maskable-512.png /apple-touch-icon.png].each do |asset|
        expect(response.body).to include("#{asset}?v=#{version}")
      end
    end

    # Auto-activating swapped assets under a live tab; now the page asks first.
    it "waits for the page to authorise the swap instead of skipping the queue" do
      get "/service-worker.js"

      expect(response.body).to include("SKIP_WAITING")
      expect(response.body).not_to match(/^\s*self\.skipWaiting\(\);$/)
    end

    it "pre-caches only assets that exist, since addAll rejects the whole install" do
      get "/service-worker.js"
      urls = response.body[/PRECACHE_URLS = \[(.*?)\]/m, 1].scan(%r{"(/[^"]+)"}).flatten

      missing = urls.reject { |url| Rails.public_path.join(url.split("?").first.delete_prefix("/")).exist? }
      expect(missing).to be_empty
    end
  end

  # PwaController drops the same-origin guard on the worker, and it can afford
  # to because nothing here mutates: the CSRF token check passes GET through
  # untouched anyway. Adding a writing action would change that, so the routes
  # are what keeps the claim true.
  describe "the surface itself" do
    it "answers nothing but GET" do
      %w[/manifest.json /service-worker.js].each do |path|
        post path
        expect(response).to have_http_status(:not_found)

        delete path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "offline.html" do
    it "serves the offline fallback page" do
      get "/offline.html"

      expect(response).to have_http_status(:ok)

      # Static files come back ASCII-8BIT, so accented copy needs the tag fixed.
      body = response.body.dup.force_encoding(Encoding::UTF_8)
      expect(body).to include("Sin conexión")
      expect(body).to include("stockerly")
    end
  end

  describe "layout" do
    it "includes manifest link and theme-color meta tag" do
      get login_path

      expect(response.body).to match(%r{<link rel="manifest" href="/manifest\.json\?v=\d+">})
      expect(response.body).to match(/<meta name="theme-color"[^>]*data-dark="#23242E"/)
    end

    # The status bar belongs to the chrome, so it tracks bg-surface; the splash
    # and the task switcher are the brand's, and stay on the manifest colour.
    it "paints the status bar from the surface token, not the brand one" do
      get "/manifest.json"
      expect(JSON.parse(response.body)["theme_color"]).to eq("#5B6CFF")

      get login_path
      expect(response.body).to include('content="#FFFFFF" data-light="#FFFFFF" data-dark="#23242E"')
    end

    it "declares a startup image for every device and scheme it ships" do
      get login_path

      IosSplash.each_image do |_device, _scheme, path|
        expect(Rails.public_path.join(path.delete_prefix("/"))).to exist
        expect(response.body).to include(%(href="#{path}?v=#{BrandAssets::VERSION}"))
      end
    end

    # Without viewport-fit=cover every env(safe-area-inset-*) in the stylesheet
    # resolves to 0, and the bottom nav sits under the iPhone home indicator.
    it "opts into the display cutout so the safe-area insets are non-zero" do
      get login_path

      expect(response.body).to include("viewport-fit=cover")
    end

    it "names the installed app so iOS does not fall back to the page title" do
      get login_path

      expect(response.body).to include('<meta name="apple-mobile-web-app-title" content="Stockerly">')
      expect(response.body).to include('<meta name="mobile-web-app-capable" content="yes">')
    end

    it "ships the update prompt hidden, for the controller to reveal" do
      login_as(create(:user))

      get dashboard_path

      expect(response.body).to include('data-controller="pwa-update"')
      expect(response.body).to match(/data-controller="pwa-update" hidden/)
    end

    it "uses one cache-bust version across layout, manifest and service worker" do
      version = cache_bust_version
      expect(version).to be_present

      get "/manifest.json"
      JSON.parse(response.body)["icons"].each do |icon|
        expect(icon["src"]).to end_with("?v=#{version}")
      end

      get "/service-worker.js"
      expect(response.body.scan(/\?v=(\d+)/).flatten.uniq).to eq([ version ])
    end
  end
end
