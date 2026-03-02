require "rails_helper"

RSpec.describe Alerts::Handlers::EvaluateSentimentAlerts do
  describe ".async?" do
    it "returns true" do
      expect(described_class.async?).to be true
    end
  end

  describe ".call" do
    it "delegates to Alerts::UseCases::EvaluateSentimentRules with event data" do
      use_case = instance_double(Alerts::UseCases::EvaluateSentimentRules)
      allow(Alerts::UseCases::EvaluateSentimentRules).to receive(:new).and_return(use_case)
      allow(use_case).to receive(:call).and_return(Dry::Monads::Success([]))

      described_class.call(index_type: "crypto", value: 72, classification: "Greed")

      expect(use_case).to have_received(:call).with(index_type: "crypto", value: 72)
    end
  end
end
