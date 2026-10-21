require "rails_helper"

RSpec.describe Notifications::UseCases::PushDailyBrief do
  let(:user) { create(:user) }

  it "reaches every install and says how many it reached, leaving the badge alone" do
    first = create(:push_subscription, user: user)
    second = create(:push_subscription, user: user)
    allow(Notifications::Domain::WebPushDelivery).to receive(:call).and_return(true, false)

    reached = described_class.call(user: user, title: "Todo en orden.", body: "Vas +1.2 pts sobre CETES.")

    expect(reached).to eq(1)
    [ first, second ].each do |subscription|
      expect(Notifications::Domain::WebPushDelivery).to have_received(:call)
        .with(subscription: subscription, title: "Todo en orden.", body: "Vas +1.2 pts sobre CETES.",
              path: "/dashboard", tag: "daily-brief")
    end
  end

  it "reaches no one when the user has no install" do
    expect(described_class.call(user: user, title: "t", body: "b")).to eq(0)
  end
end
