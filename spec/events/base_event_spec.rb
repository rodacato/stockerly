require "rails_helper"

RSpec.describe BaseEvent do
  let(:test_event_class) do
    Class.new(BaseEvent) do
      attribute :user_id, Types::Integer

      def self.name
        "UserRegistered"
      end
    end
  end

  describe "attributes" do
    it "sets occurred_at to current time by default" do
      event = test_event_class.new(user_id: 1)
      expect(event.occurred_at).to be_within(1.second).of(DateTime.current)
    end

    it "allows custom occurred_at" do
      custom_time = DateTime.new(2025, 1, 1)
      event = test_event_class.new(user_id: 1, occurred_at: custom_time)

      expect(event.occurred_at).to eq(custom_time)
    end
  end

  describe "#event_name" do
    it "returns underscored class name" do
      event = test_event_class.new(user_id: 1)
      expect(event.event_name).to eq("user_registered")
    end

    it "converts namespaced class names with dots" do
      namespaced_class = Class.new(BaseEvent) do
        attribute :data, Types::String

        def self.name
          "Admin::UserSuspended"
        end
      end

      event = namespaced_class.new(data: "test")
      expect(event.event_name).to eq("admin.user_suspended")
    end
  end

  describe "#to_h" do
    it "serializes all attributes to a hash" do
      event = test_event_class.new(user_id: 42)
      hash = event.to_h

      expect(hash).to include(user_id: 42)
      expect(hash).to have_key(:occurred_at)
    end
  end
end
