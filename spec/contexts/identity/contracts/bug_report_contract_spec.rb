require "rails_helper"

RSpec.describe Identity::Contracts::BugReportContract do
  subject(:contract) { described_class.new }

  let(:valid_params) { { title: "La gráfica no carga", description: "Cuando abro /portfolio no aparece nada y la consola muestra 500." } }

  it "passes with valid params" do
    expect(contract.call(valid_params)).to be_success
  end

  it "fails with missing title" do
    result = contract.call(valid_params.merge(title: ""))
    expect(result).to be_failure
    expect(result.errors[:title]).to be_present
  end

  it "fails with short title" do
    result = contract.call(valid_params.merge(title: "ab"))
    expect(result).to be_failure
    expect(result.errors[:title]).to be_present
  end

  it "fails with short description" do
    result = contract.call(valid_params.merge(description: "too short"))
    expect(result).to be_failure
    expect(result.errors[:description]).to be_present
  end

  it "fails with missing description" do
    result = contract.call(valid_params.merge(description: ""))
    expect(result).to be_failure
    expect(result.errors[:description]).to be_present
  end
end
