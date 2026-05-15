require "rails_helper"

RSpec.describe Notifications::UseCases::ListRecent do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns notifications relation + unread_count" do
      create(:notification, user: user, read: false)
      create(:notification, user: user, read: true)

      data = described_class.call(user: user)

      expect(data[:notifications].count).to eq(2)
      expect(data[:unread_count]).to eq(1)
    end

    it "returns zero unread_count when all notifications are read" do
      create(:notification, user: user, read: true)
      expect(described_class.call(user: user)[:unread_count]).to eq(0)
    end
  end
end
