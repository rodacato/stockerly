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

    it "does not offer the Alpaca notice once the integration is connected" do
      create(:integration, provider_name: "Alpaca", connection_status: :connected)

      get discover_path

      expect(response.body).not_to include("Conecta Alpaca")
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

  # D31's disposability contract, pinned: this screen owns no table, so
  # deleting it must never require a migration.
  it "reads no ActiveRecord model of its own" do
    expect(defined?(DiscoverItem)).to be_nil
    expect(ActiveRecord::Base.connection.tables).not_to include("discover_items")
  end
end
