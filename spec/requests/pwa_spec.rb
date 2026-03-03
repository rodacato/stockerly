require "rails_helper"

RSpec.describe "PWA", type: :request do
  describe "manifest.json" do
    it "serves valid manifest with correct metadata" do
      get "/manifest.json"

      expect(response).to have_http_status(:ok)
      manifest = JSON.parse(response.body)
      expect(manifest["short_name"]).to eq("Stockerly")
      expect(manifest["start_url"]).to eq("/dashboard")
      expect(manifest["display"]).to eq("standalone")
      expect(manifest["theme_color"]).to eq("#004a99")
      expect(manifest["icons"].size).to be >= 2
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
      get "/service-worker.js"

      expect(response.body).to include("/offline.html")
      expect(response.body).to include("/icon-192.png")
      expect(response.body).to include("/icon-512.png")
    end
  end

  describe "offline.html" do
    it "serves the offline fallback page" do
      get "/offline.html"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Offline")
      expect(response.body).to include("Stockerly")
    end
  end

  describe "layout" do
    it "includes manifest link and theme-color meta tag" do
      get root_path

      expect(response.body).to include('<link rel="manifest" href="/manifest.json">')
      expect(response.body).to include('<meta name="theme-color" content="#004a99">')
    end
  end
end
