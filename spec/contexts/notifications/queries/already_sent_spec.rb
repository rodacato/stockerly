require "rails_helper"

RSpec.describe Notifications::Queries::AlreadySent do
  let(:user) { create(:user) }
  let(:event) { create(:earnings_event) }

  describe ".call" do
    it "is true once the notification exists for that user, subject and type" do
      create(:notification, user: user, notifiable: event, notification_type: :earnings_reminder)

      expect(described_class.call(user: user, notifiable: event, notification_type: :earnings_reminder)).to be(true)
    end

    it "is false when nothing was sent" do
      expect(described_class.call(user: user, notifiable: event, notification_type: :earnings_reminder)).to be(false)
    end

    it "does not count another user's notification about the same subject" do
      create(:notification, user: create(:user), notifiable: event, notification_type: :earnings_reminder)

      expect(described_class.call(user: user, notifiable: event, notification_type: :earnings_reminder)).to be(false)
    end

    it "does not count a different notification type about the same subject" do
      create(:notification, user: user, notifiable: event, notification_type: :alert_triggered)

      expect(described_class.call(user: user, notifiable: event, notification_type: :earnings_reminder)).to be(false)
    end
  end

  describe ".notifiable_ids_on" do
    let(:portfolio) { create(:portfolio, user: user) }
    let(:position) { create(:position, portfolio: portfolio) }
    let(:other_position) { create(:position, portfolio: portfolio) }

    def ids_today(ids)
      described_class.notifiable_ids_on(
        date: Date.current,
        notifiable_type: "Position",
        notifiable_ids: ids,
        notification_type: :maturity_reminder
      )
    end

    it "returns the ids notified on that date" do
      create(:notification, user: user, notifiable: position, notification_type: :maturity_reminder)

      expect(ids_today([ position.id, other_position.id ])).to eq(Set.new([ position.id ]))
    end

    it "ignores a notification sent on another day" do
      create(:notification, user: user, notifiable: position,
             notification_type: :maturity_reminder, created_at: 2.days.ago)

      expect(ids_today([ position.id ])).to be_empty
    end

    it "queries nothing when asked about no subjects" do
      expect(Notification).not_to receive(:where)

      expect(ids_today([])).to be_empty
    end
  end
end
