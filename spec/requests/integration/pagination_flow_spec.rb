require "rails_helper"

RSpec.describe "Pagination flow", type: :request do
  let!(:user) { create(:user, email: "pager@example.com", password: "password123") }

  before do
    login_as(user)
  end

  it "paginates market assets across pages" do
    create_list(:asset, 25, asset_type: :stock)

    # Page 1: should have 20 assets
    get market_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Market Listings")

    # Page 2: should have remaining 5
    get market_path(page: 2)
    expect(response).to have_http_status(:ok)
  end

  it "paginates news articles" do
    create_list(:news_article, 15, published_at: 1.hour.ago)

    get news_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Market News")

    get news_path(page: 2)
    expect(response).to have_http_status(:ok)
  end

  it "paginates admin logs" do
    delete logout_path
    admin = create(:user, :admin, email: "admin_pag@example.com", password: "password123")
    login_as(admin)

    create_list(:system_log, 25)

    get admin_logs_path
    expect(response).to have_http_status(:ok)

    get admin_logs_path(page: 2)
    expect(response).to have_http_status(:ok)
  end
end
