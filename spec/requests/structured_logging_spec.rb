require "rails_helper"

RSpec.describe "Structured logging payload", type: :request do
  let!(:user) { create(:user, email: "logger@example.com", password: "password123") }

  describe "append_info_to_payload" do
    it "includes user_id in payload for authenticated requests" do
      login_as(user)

      payloads = []
      callback = lambda { |_name, _start, _finish, _id, payload| payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, "process_action.action_controller") do
        get dashboard_path
      end

      expect(payloads.last[:user_id]).to eq(user.id)
      expect(payloads.last[:ip]).to be_present
    end

    it "sets user_id to nil for unauthenticated requests" do
      payloads = []
      callback = lambda { |_name, _start, _finish, _id, payload| payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, "process_action.action_controller") do
        get root_path
      end

      expect(payloads.last[:user_id]).to be_nil
      expect(payloads.last[:ip]).to be_present
    end
  end
end
