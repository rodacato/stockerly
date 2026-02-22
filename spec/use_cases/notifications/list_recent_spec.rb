require "rails_helper"

RSpec.describe Notifications::ListRecent do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns Success with notifications and unread_count" do
      create(:notification, user: user, read: false)
      create(:notification, user: user, read: true)

      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:notifications].count).to eq(2)
      expect(data[:unread_count]).to eq(1)
    end

    it "returns zero unread when all read" do
      create(:notification, user: user, read: true)

      result = described_class.call(user: user)
      expect(result.value![:unread_count]).to eq(0)
    end
  end
end
