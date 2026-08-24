require "rails_helper"

# D2 picked lightweight-charts so the chart is served from this instance rather
# than a third-party iframe. These pin that the whole module graph stays local.
RSpec.describe "Chart assets", type: :request do
  let(:importmap) do
    get "/login"
    JSON.parse(response.body[%r{<script type="importmap".*?>(.*?)</script>}m, 1])
  end

  it "maps lightweight-charts and its fancy-canvas dependency" do
    expect(importmap["imports"]).to include("lightweight-charts", "fancy-canvas")
  end

  it "serves both modules from this instance, not from a CDN" do
    %w[lightweight-charts fancy-canvas].each do |package|
      path = importmap["imports"].fetch(package)
      expect(path).to start_with("/assets/")

      get path
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end
  end

  it "leaves no bare import the browser cannot resolve" do
    get importmap["imports"].fetch("lightweight-charts")

    bare_imports = response.body.scan(/from\s*["']([^"'.\/][^"']*)["']/).flatten.uniq
    expect(bare_imports - importmap["imports"].keys).to be_empty
  end
end
