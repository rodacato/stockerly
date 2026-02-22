require "rails_helper"

RSpec.describe EventBus do
  let(:test_event_class) do
    Class.new(BaseEvent) do
      attribute :user_id, Types::Integer

      def self.name
        "TestEvent"
      end
    end
  end

  let(:event) { test_event_class.new(user_id: 1) }

  after { EventBus.clear! }

  describe ".subscribe" do
    it "registers a handler for an event class" do
      handler = ->(e) {}
      EventBus.subscribe(test_event_class, handler)

      expect(EventBus.handlers_for(test_event_class)).to include(handler)
    end

    it "allows multiple handlers for the same event" do
      handler1 = ->(e) {}
      handler2 = ->(e) {}
      EventBus.subscribe(test_event_class, handler1)
      EventBus.subscribe(test_event_class, handler2)

      expect(EventBus.handlers_for(test_event_class).size).to eq(2)
    end
  end

  describe ".publish" do
    it "calls all sync handlers with the event" do
      received = []
      handler = ->(e) { received << e }
      EventBus.subscribe(test_event_class, handler)

      EventBus.publish(event)

      expect(received).to eq([event])
    end

    it "calls multiple handlers in order" do
      order = []
      EventBus.subscribe(test_event_class, ->(_e) { order << :first })
      EventBus.subscribe(test_event_class, ->(_e) { order << :second })

      EventBus.publish(event)

      expect(order).to eq([:first, :second])
    end

    it "does nothing when no handlers are registered" do
      expect { EventBus.publish(event) }.not_to raise_error
    end

    it "enqueues async handlers via ProcessEventJob" do
      async_handler = Class.new do
        def self.name
          "AsyncTestHandler"
        end

        def self.async?
          true
        end

        def self.call(data); end
      end

      EventBus.subscribe(test_event_class, async_handler)

      expect(ProcessEventJob).to receive(:perform_later).with("AsyncTestHandler", hash_including(user_id: 1))

      EventBus.publish(event)
    end
  end

  describe ".clear!" do
    it "removes all registered handlers" do
      EventBus.subscribe(test_event_class, ->(e) {})
      EventBus.clear!

      expect(EventBus.handlers_for(test_event_class)).to be_empty
    end
  end

  describe ".handlers_for" do
    it "returns a copy of handlers for an event class" do
      handler = ->(e) {}
      EventBus.subscribe(test_event_class, handler)

      handlers = EventBus.handlers_for(test_event_class)
      handlers.clear

      expect(EventBus.handlers_for(test_event_class)).to include(handler)
    end

    it "returns empty array for unknown event class" do
      unknown_class = Class.new(BaseEvent) do
        def self.name
          "UnknownEvent"
        end
      end

      expect(EventBus.handlers_for(unknown_class)).to be_empty
    end
  end
end
