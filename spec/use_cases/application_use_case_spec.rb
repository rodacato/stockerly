require "rails_helper"

RSpec.describe ApplicationUseCase do
  describe ".call" do
    it "instantiates and calls the use case" do
      test_use_case = Class.new(ApplicationUseCase) do
        def call(value:)
          Success(value * 2)
        end
      end

      result = test_use_case.call(value: 5)

      expect(result).to be_success
      expect(result.value!).to eq(10)
    end
  end

  describe "#validate" do
    let(:test_contract) do
      Class.new(ApplicationContract) do
        params do
          required(:name).filled(:string)
          required(:age).filled(:integer, gt?: 0)
        end
      end
    end

    let(:use_case_class) do
      contract = test_contract
      Class.new(ApplicationUseCase) do
        define_method(:call) do |params:|
          validate(contract, params)
        end
      end
    end

    it "returns Success with validated params when valid" do
      result = use_case_class.call(params: { name: "Alex", age: 30 })

      expect(result).to be_success
      expect(result.value!).to eq({ name: "Alex", age: 30 })
    end

    it "returns Failure with :validation tag when invalid" do
      result = use_case_class.call(params: { name: "", age: -1 })

      expect(result).to be_failure
      failure = result.failure
      expect(failure[0]).to eq(:validation)
      expect(failure[1]).to have_key(:name)
      expect(failure[1]).to have_key(:age)
    end
  end

  describe "#publish" do
    let(:test_event_class) do
      Class.new(BaseEvent) do
        attribute :user_id, Types::Integer

        def self.name
          "TestPublishEvent"
        end
      end
    end

    let(:use_case_class) do
      evt_class = test_event_class
      Class.new(ApplicationUseCase) do
        define_method(:call) do |user_id:|
          event = evt_class.new(user_id: user_id)
          publish(event)
        end
      end
    end

    it "publishes the event via EventBus and returns Success" do
      received = []
      EventBus.subscribe(test_event_class, ->(e) { received << e })

      result = use_case_class.call(user_id: 42)

      expect(result).to be_success
      expect(received.size).to eq(1)
      expect(received.first.user_id).to eq(42)
    end
  end
end
