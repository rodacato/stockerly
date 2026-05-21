require "rails_helper"

RSpec.describe EvaluateDateBasedAlertsJob, type: :job do
  it "delegates to Alerts::UseCases::EvaluateDateBasedRules" do
    instance = instance_double(Alerts::UseCases::EvaluateDateBasedRules, call: Dry::Monads::Success([]))
    allow(Alerts::UseCases::EvaluateDateBasedRules).to receive(:new).and_return(instance)

    described_class.perform_now

    expect(instance).to have_received(:call)
  end
end
