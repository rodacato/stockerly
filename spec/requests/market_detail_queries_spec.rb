require "rails_helper"

# X21 / #457: the asset detail's assembly moved out of the template, so the
# view renders what it is handed. This pins that — a fetch reintroduced into a
# partial shows up here as a higher count.
RSpec.describe "Market Asset Detail — query budget", type: :request do
  let!(:user) { create(:user, email: "budget@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 150.0) }

  before do
    login_as(user)
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
           metrics: { "fifty_two_week_high" => "180.0", "fifty_two_week_low" => "120.0" })
    create(:technical_reading, asset: asset)
    5.downto(1) { |n| create(:asset_price_history, asset: asset, date: n.days.ago.to_date, close: 140 + n) }
    get market_asset_path(asset.symbol) # warm the schema cache
  end

  def count_queries
    count = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(sub)
  end

  # Measured at 21 on the commit that moved the assembly, and 21 on the commit
  # before it — this refactor was meant to change where the work happens, not
  # how much of it there is. The margin absorbs an added column, not an added
  # fetch.
  it "loads the detail within its query budget" do
    queries = count_queries { get market_asset_path(asset.symbol) }

    expect(response).to have_http_status(:ok)
    expect(queries).to be <= 25
  end
end
