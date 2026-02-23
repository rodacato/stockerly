require "rails_helper"

RSpec.describe "Alert lifecycle", type: :request do
  let!(:user) { create(:user, email: "alerts@example.com", password: "password123") }

  before do
    login_as(user)
  end

  it "creates, toggles, and destroys an alert rule" do
    # Create
    post alerts_path, params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }
    expect(response).to redirect_to(alerts_path)

    rule = user.alert_rules.last
    expect(rule).to be_present
    expect(rule.asset_symbol).to eq("AAPL")
    expect(rule).to be_active

    # Toggle to paused
    patch toggle_alert_path(rule)
    expect(response).to redirect_to(alerts_path)
    expect(rule.reload).to be_paused

    # Toggle back to active
    patch toggle_alert_path(rule)
    expect(rule.reload).to be_active

    # Destroy
    delete alert_path(rule)
    expect(response).to redirect_to(alerts_path)
    expect(user.alert_rules.count).to eq(0)
  end

  it "updates an existing alert rule" do
    rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 150.0)

    patch alert_path(rule), params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 250.0 } }
    expect(response).to redirect_to(alerts_path)
    expect(rule.reload.threshold_value).to eq(250.0)
  end
end
