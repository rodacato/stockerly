require "rails_helper"

RSpec.describe Trading::UseCases::NotifyApproachingMaturities do
  subject(:use_case) { described_class }

  let(:user) { create(:user, preferred_currency: "MXN") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 Days") }

  def maturing_in(days, attrs = {})
    create(
      :position,
      portfolio: portfolio,
      asset: cetes,
      shares: 100.0,
      avg_cost: 9.85,
      status: :open,
      maturity_date: days.days.from_now.to_date,
      **attrs
    )
  end

  describe ".call" do
    [ 7, 3, 1 ].each do |days|
      it "fires a maturity_reminder at the #{days}-day threshold" do
        position = maturing_in(days)

        expect { use_case.call }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.notification_type).to eq("maturity_reminder")
        expect(notification.notifiable).to eq(position)
        expect(notification.user).to eq(user)
        expect(notification.title).to include("CETES_28D")
        expect(notification.body).to include("CETES 28 Days")
      end
    end

    it "uses 'tomorrow' for the 1-day threshold (descriptive copy per ADR-001)" do
      maturing_in(1)
      use_case.call
      expect(Notification.last.title).to eq("CETES_28D expires tomorrow")
    end

    it "uses 'in N days' for the 7-day threshold" do
      maturing_in(7)
      use_case.call
      expect(Notification.last.title).to eq("CETES_28D expires in 7 days")
    end

    it "returns the count of notifications sent" do
      maturing_in(7)
      maturing_in(3, asset: create(:asset, :fixed_income, symbol: "CETES_91D"))

      result = use_case.call
      expect(result).to be_success
      expect(result.value!).to eq(2)
    end

    it "does NOT fire outside threshold days (e.g. 5 days remaining)" do
      maturing_in(5)
      expect { use_case.call }.not_to change(Notification, :count)
    end

    it "does NOT fire for already-expired positions" do
      maturing_in(-1)
      expect { use_case.call }.not_to change(Notification, :count)
    end

    it "does NOT fire on the maturity day itself (0 days; the 1-day reminder already covered it)" do
      maturing_in(0)
      expect { use_case.call }.not_to change(Notification, :count)
    end

    it "ignores closed positions" do
      maturing_in(3, status: :closed, closed_at: Time.current)
      expect { use_case.call }.not_to change(Notification, :count)
    end

    it "ignores positions without a maturity_date (non-fixed-income assets)" do
      stock = create(:asset, :stock, symbol: "AAPL")
      create(:position, portfolio: portfolio, asset: stock, maturity_date: nil)

      expect { use_case.call }.not_to change(Notification, :count)
    end

    describe "cooldown (one notification per position per calendar day)" do
      it "does not double-fire when called twice on the same day" do
        maturing_in(3)
        use_case.call
        expect { use_case.call }.not_to change(Notification, :count)
      end

      it "fires again on a subsequent day if a different threshold is hit" do
        # Day 7 fires; day 3 also fires (different position, different day).
        # We simulate two separate runs by leveraging the cooldown's "today"
        # check: today's run dedups via Notification.created_at::date.
        position = maturing_in(7)
        use_case.call
        expect(Notification.count).to eq(1)

        # Simulate the 4 days passing: position now at 3 days out.
        # The cooldown query is `Notification.where(created_at: Date.current.all_day)`
        # — so backdating the existing notification simulates "yesterday".
        Notification.last.update_columns(created_at: 4.days.ago)
        position.update!(maturity_date: 3.days.from_now.to_date)

        expect { use_case.call }.to change(Notification, :count).by(1)
        expect(Notification.last.title).to eq("CETES_28D expires in 3 days")
      end
    end
  end
end
