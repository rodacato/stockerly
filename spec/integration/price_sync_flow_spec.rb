require "rails_helper"

RSpec.describe "Price Sync Flow (E2E)", type: :model do
  include ActiveJob::TestHelper

  let(:user)  { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 150.00, price_updated_at: 10.minutes.ago) }
  let!(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 180, status: :active) }

  before { stub_polygon_price("AAPL", close: 189.43) }

  it "syncs price → evaluates alerts → creates notification" do
    # Wire up event subscriptions for this test
    EventBus.subscribe(AssetPriceUpdated, EvaluateAlertsOnPriceUpdate)
    EventBus.subscribe(AlertRuleTriggered, CreateAlertEventOnTrigger)
    EventBus.subscribe(AlertRuleTriggered, CreateNotificationOnAlert)

    # Execute the sync job and all async handlers inline
    perform_enqueued_jobs do
      SyncSingleAssetJob.perform_now(asset.id)
    end

    # 1. Asset price was updated
    asset.reload
    expect(asset.current_price.to_f).to eq(189.43)
    expect(asset.price_updated_at).to be_present

    # 2. Alert was evaluated and triggered
    expect(AlertEvent.count).to eq(1)
    alert_event = AlertEvent.last
    expect(alert_event.asset_symbol).to eq("AAPL")
    expect(alert_event.event_status).to eq("triggered")

    # 3. Notification was created
    expect(Notification.count).to eq(1)
    notification = Notification.last
    expect(notification.user).to eq(user)
    expect(notification.title).to include("AAPL")
    expect(notification.notification_type).to eq("alert_triggered")

    # 4. SystemLog was created
    expect(SystemLog.where(task_name: "Price Sync: AAPL").count).to eq(1)
  end
end
