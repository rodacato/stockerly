require "rails_helper"

# End to end: the sheet accepts a trade I made days ago, and the history it
# lands in stops describing a portfolio that did not include it.
RSpec.describe "Recording a trade I made days ago", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user))
      .tap { |p| p.update!(inception_date: 30.days.ago.to_date) }
  end

  before do
    EventBus.subscribe(Trading::Events::TradeExecuted, Trading::Handlers::RebuildSnapshotsOnBackdatedTrade)
    login_as(user)
  end

  it "rebuilds the days that predated it" do
    asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 10)
    create(:asset_price_history, asset: asset, date: 5.days.ago.to_date, close: 10)
    portfolio.snapshots.create!(date: 5.days.ago.to_date, currency: "MXN",
                                total_value: 0, invested_value: 0)

    perform_enqueued_jobs do
      post trades_path, params: {
        trade: { asset_symbol: "WALMEX", side: "buy", shares: 100,
                 price_per_share: 10, executed_at: 5.days.ago.to_date.to_s }
      }
    end

    expect(portfolio.snapshots.find_by(date: 5.days.ago.to_date).invested_value).to eq(1_000)
  end

  it "refuses a trade dated in the future, in es-MX" do
    create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 10)

    post trades_path, params: {
      trade: { asset_symbol: "WALMEX", side: "buy", shares: 100,
               price_per_share: 10, executed_at: 30.days.from_now.to_date.to_s }
    }

    expect(Trade.count).to eq(0)
    expect(flash[:alert]).to eq(I18n.t("trades.errores.fecha_futura"))
  end
end
