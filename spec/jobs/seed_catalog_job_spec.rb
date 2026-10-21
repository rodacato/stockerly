require "rails_helper"

RSpec.describe SeedCatalogJob, type: :job do
  it "creates what the catalogue declares and logs the tally" do
    described_class.perform_now

    expect(Asset.count).to be_positive
    expect(SystemLog.last).to have_attributes(task_name: described_class::TASK, severity: "success")
  end

  it "changes nothing the second time" do
    described_class.perform_now

    expect { described_class.perform_now }.not_to change(Asset, :count)
    expect(SystemLog.last.error_message).to start_with("0 created, 0 corrected")
  end
end
