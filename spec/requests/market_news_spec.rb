require "rails_helper"

# CKP-11 / #427: the asset detail's news block. Behavioral specs for the
# query live in spec/contexts/market_data/queries/recent_news_spec.rb.
RSpec.describe "Market Asset Detail — news", type: :request do
  let!(:user) { create(:user, email: "news@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }

  before { login_as(user) }

  it "renders recent headlines as their source wrote them" do
    create(:news_article, related_ticker: "AAPL", title: "Apple beats on services revenue",
                          source: "Bloomberg", published_at: 2.hours.ago)

    get market_asset_path(asset.symbol)

    expect(response.body).to include(I18n.t("market.news.titulo"))
    expect(response.body).to include("Apple beats on services revenue")
    expect(response.body).to include("Bloomberg")
  end

  # Nothing happened is not a screen.
  it "omits the block entirely when the asset has no recent articles" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(I18n.t("market.news.titulo"))
  end

  it "omits an article older than the window rather than rendering it as old" do
    create(:news_article, related_ticker: "AAPL", title: "Three weeks ago and unrelated",
                          published_at: 21.days.ago)

    get market_asset_path(asset.symbol)

    expect(response.body).not_to include("Three weeks ago and unrelated")
    expect(response.body).not_to include(I18n.t("market.news.titulo"))
  end

  it "keeps articles filed under a symbol the asset used to carry" do
    asset.update!(symbol: "META", former_symbols: [ "FB" ])
    create(:news_article, related_ticker: "FB", title: "Filed under the old ticker",
                          published_at: 1.day.ago)

    get market_asset_path("META")

    expect(response.body).to include("Filed under the old ticker")
  end
end
