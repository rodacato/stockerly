require "rails_helper"

RSpec.describe SendDailyBriefJob, type: :job do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before do
    allow(Notifications::Domain::WebPushDelivery).to receive(:call).and_return(true)
  end

  def opt_in(daily_push: true)
    create(:alert_preference, user: user, daily_push: daily_push)
    create(:push_subscription, user: user)
  end

  def hold
    asset = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70)
    create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)
  end

  it "pushes Hoy's own sentence to someone who asked, and a calm day is a message too" do
    opt_in
    hold

    described_class.perform_now

    expect(Notifications::Domain::WebPushDelivery).to have_received(:call)
      .with(hash_including(title: "Todo en orden.", path: "/dashboard", badge_count: 0))
    expect(SystemLog.where(task_name: "Daily Brief").last.error_message).to eq("1 install(s) reached")
  end

  it "carries what is worth a look, in the catalogue's words" do
    opt_in
    held = create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70)
    create(:position, portfolio: portfolio, asset: held, shares: 100, avg_cost: 60, status: :open)
    create(:earnings_event, asset: held, report_date: 2.days.from_now.to_date)

    described_class.perform_now

    expect(Notifications::Domain::WebPushDelivery).to have_received(:call)
      .with(hash_including(title: "Hay 1 cosa de lo tuyo para mirar hoy.", body: "WALMEX reporta resultados"))
  end

  it "says nothing to someone with nothing tracked yet" do
    opt_in

    described_class.perform_now

    expect(Notifications::Domain::WebPushDelivery).not_to have_received(:call)
  end

  it "skips whoever did not ask, and whoever has no install" do
    hold
    create(:alert_preference, user: user, daily_push: true)

    described_class.perform_now
    expect(Notifications::Domain::WebPushDelivery).not_to have_received(:call)

    create(:push_subscription, user: user)
    user.alert_preference.update!(daily_push: false)
    described_class.perform_now
    expect(Notifications::Domain::WebPushDelivery).not_to have_received(:call)
  end

  it "logs the failure and re-raises" do
    opt_in
    allow(Trading::UseCases::AssemblePanorama).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now }.to raise_error(StandardError, "boom")
    expect(SystemLog.where(task_name: "Daily Brief").last.severity).to eq("error")
  end
end
