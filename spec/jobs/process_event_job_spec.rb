require "rails_helper"

RSpec.describe ProcessEventJob, type: :job do
  describe "#perform" do
    it "constantizes handler and calls it with event data" do
      handler = Class.new do
        def self.name
          "TestJobHandler"
        end

        def self.call(data)
          data
        end
      end

      stub_const("TestJobHandler", handler)

      expect(TestJobHandler).to receive(:call).with({ user_id: 1, email: "test@example.com" })

      ProcessEventJob.new.perform("TestJobHandler", { "user_id" => 1, "email" => "test@example.com" })
    end

    it "symbolizes string keys in event data" do
      handler = Class.new do
        def self.name
          "SymbolizeHandler"
        end

        def self.call(data)
          data
        end
      end

      stub_const("SymbolizeHandler", handler)

      expect(SymbolizeHandler).to receive(:call).with({ name: "Alex" })

      ProcessEventJob.new.perform("SymbolizeHandler", { "name" => "Alex" })
    end
  end

  describe "queue" do
    it "uses the default queue" do
      expect(ProcessEventJob.new.queue_name).to eq("default")
    end
  end
end
