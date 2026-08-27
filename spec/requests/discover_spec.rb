require "rails_helper"

RSpec.describe "Descubrir", type: :request do
  let!(:user) { create(:user, email: "discover@example.com", password: "password123") }

  before { login_as(user) }

  describe "GET /discover" do
    it "returns success" do
      get discover_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the calendar, the block that needs no credential" do
      get discover_path

      expect(response.body).to include("Calendario")
      expect(response.body).to include("Banxico")
      expect(response.body).to include("Fed")
    end

    # Olas, reportes and titulares read Alpaca, which no instance has yet.
    # The screen names what is missing instead of drawing empty cards.
    it "says which credential the other blocks are waiting on" do
      get discover_path

      expect(response.body).to include("Conecta Alpaca")
      expect(response.body).to include(admin_integrations_path)
    end

    # A connected credential whose job has not run yet still has nothing to
    # show, so what retires the notice is world data, not the integration row.
    it "keeps the notice while there is no world data, connected or not" do
      create(:integration, provider_name: "Alpaca", connection_status: :connected)

      get discover_path

      expect(response.body).to include("Conecta Alpaca")
    end
  end

  # The mobile bar carries no title, so the shell emits an sr-only h1 for the
  # screens whose artboard has none. This one's does, so it renders its own —
  # and the shell must stand down, because two h1s on a page is a defect.
  describe "its heading" do
    # Two h1s sit in the DOM on every screen — the desktop bar's and the
    # mobile one — and CSS picks. What must not happen is a third.
    it "adds no h1 beyond what a screen without its own heading has" do
      get dashboard_path
      baseline = response.body.scan("<h1").size

      get discover_path

      expect(response.body.scan("<h1").size).to eq(baseline)
    end

    it "is the screen's own, visible below lg rather than the shell's sr-only" do
      get discover_path

      expect(response.body).to match(/<h1[^>]*lg:hidden[^>]*>\s*Descubrir/)
      expect(response.body).not_to include('<h1 class="sr-only lg:hidden">')
    end
  end

  describe "the nav" do
    it "is reachable as the fifth destination" do
      get dashboard_path

      expect(response.body).to include(%(href="#{discover_path}"))
      expect(response.body).to include("Descubrir")
    end
  end

  describe "authentication guard" do
    it "redirects to login when not authenticated" do
      delete logout_path
      get discover_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Olas" do
    # :null_store is the test default and this screen's only storage is the
    # cache, so without a real one these would assert against nothing.
    let(:memory) { ActiveSupport::Cache::MemoryStore.new }
    let(:wave) do
      MarketData::Discover::WaveRanking::Wave.new(
        symbol: "SMH", name: "Semiconductores", group: "sectores",
        change_percent: 8.4, vs_baseline: 5.2, closes: [ 100.0, 104.0, 108.0 ],
        referents: [ "NVDA" ]
      )
    end

    before do
      allow(Rails).to receive(:cache).and_return(memory)
      memory.write(WarmDiscoverJob::CACHE_KEY,
                   { waves: [ wave ], since: 8.days.ago.to_date, generated_at: Time.current })
    end

    it "ranks the basket with its move and its distance from the baseline" do
      get discover_path

      expect(response.body).to include("SMH", "Semiconductores", "8.4%", "5.2")
    end

    it "says there is no exposure when none of the referents is held" do
      get discover_path

      expect(response.body).to include("sin exposición")
    end

    it "names the holding that already gives exposure" do
      portfolio = user.portfolio || create(:portfolio, user: user)
      nvda = create(:asset, symbol: "NVDA")
      create(:position, portfolio: portfolio, asset: nvda, status: :open)

      get discover_path

      expect(response.body).to include("ya vía NVDA")
      expect(response.body).not_to include("sin exposición")
    end

    it "retires the Alpaca notice once there are waves to show" do
      get discover_path

      expect(response.body).not_to include("Conecta Alpaca")
    end

    it "shows no Olas block at all when the job has not run" do
      memory.delete(WarmDiscoverJob::CACHE_KEY)

      get discover_path

      expect(response.body).not_to include("Olas")
    end
  end

  # D31's disposability contract, pinned: this screen owns no table, so
  # deleting it must never require a migration.
  it "reads no ActiveRecord model of its own" do
    expect(defined?(DiscoverItem)).to be_nil
    expect(ActiveRecord::Base.connection.tables).not_to include("discover_items")
  end
end
