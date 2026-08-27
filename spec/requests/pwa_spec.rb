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
  end

  describe "service-worker.js" do
    it "serves the service worker script" do
      get "/service-worker.js"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CACHE_VERSION")
      expect(response.body).to include("stockerly-static")
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
      %w[/favicon.svg /icon-192.png /icon-512.png /apple-touch-icon.png].each do |asset|
        expect(response.body).to include("#{asset}?v=#{version}")
      end
    end

    it "pre-caches only assets that exist, since addAll rejects the whole install" do
      get "/service-worker.js"
      urls = response.body[/PRECACHE_URLS = \[(.*?)\]/m, 1].scan(%r{"(/[^"]+)"}).flatten

      missing = urls.reject { |url| Rails.public_path.join(url.split("?").first.delete_prefix("/")).exist? }
      expect(missing).to be_empty
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
      expect(response.body).to include('<meta name="theme-color" content="#5B6CFF">')
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
