require "rails_helper"

RSpec.describe MarketData::UseCases::NotifyApproachingEarnings do
  let!(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.") }

  describe ".call" do
    context "with upcoming earnings for watched assets" do
      let!(:watchlist_item) { create(:watchlist_item, user: user, asset: asset) }
      let!(:event) do
        create(:earnings_event, asset: asset, report_date: 2.days.from_now.to_date, estimated_eps: 2.50)
      end

      it "creates earnings reminder notifications" do
        expect { described_class.call }.to change(Notification, :count).by(1)
      end

      it "returns count of notifications created" do
        result = described_class.call
        expect(result).to be_success
        expect(result.value!).to eq(1)
      end

      it "sets correct notification attributes" do
        described_class.call

        notification = Notification.last
        expect(notification.notification_type).to eq("earnings_reminder")
        expect(notification.title).to include("AAPL")
        expect(notification.body).to include("Apple Inc.")
        expect(notification.body).to include("2 days")
        expect(notification.notifiable).to eq(event)
      end

      it "does not create duplicate notifications" do
        described_class.call
        expect { described_class.call }.not_to change(Notification, :count)
      end
    end

    context "with upcoming earnings for held positions" do
      let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 150, status: :open) }
      let!(:event) do
        create(:earnings_event, asset: asset, report_date: Date.current, estimated_eps: 2.50)
      end

      it "notifies users with open positions" do
        expect { described_class.call }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.body).to include("today")
      end
    end

    context "with no upcoming earnings" do
      it "returns zero" do
        result = described_class.call
        expect(result).to be_success
        expect(result.value!).to eq(0)
      end
    end

    context "with earnings outside the lookahead window" do
      let!(:watchlist_item) { create(:watchlist_item, user: user, asset: asset) }
      let!(:event) do
        create(:earnings_event, asset: asset, report_date: 10.days.from_now.to_date, estimated_eps: 2.50)
      end

      it "does not create notifications" do
        expect { described_class.call }.not_to change(Notification, :count)
      end
    end
  end
end
