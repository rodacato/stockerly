require "rails_helper"

RSpec.describe Notifications::UseCases::DestroyRead do
  let(:user) { create(:user) }

  describe ".call" do
    it "deletes only the user's read notifications and returns the count removed" do
      create_list(:notification, 3, user: user, read: true)
      create_list(:notification, 2, user: user, read: false)

      result = described_class.call(user: user)

      expect(result).to eq(3)
      expect(user.notifications.count).to eq(2)
      expect(user.notifications.unread.count).to eq(2)
    end

    it "does not touch other users' notifications" do
      other = create(:user)
      create(:notification, user: other, read: true)
      create(:notification, user: user,  read: true)

      described_class.call(user: user)

      expect(other.notifications.count).to eq(1)
      expect(user.notifications.count).to eq(0)
    end

    it "returns zero when there are no read notifications" do
      create(:notification, user: user, read: false)
      expect(described_class.call(user: user)).to eq(0)
    end
  end
end
