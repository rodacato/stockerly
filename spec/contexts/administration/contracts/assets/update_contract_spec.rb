require "rails_helper"

RSpec.describe Administration::Contracts::Assets::UpdateContract do
  subject(:contract) { described_class.new }

  let(:valid_params) { { id: 1 } }

  it "passes with only id" do
    result = contract.call(valid_params)
    expect(result).to be_success
  end

  it "passes with all optional params" do
    result = contract.call(valid_params.merge(
      name: "Apple Inc.", exchange: "NASDAQ", country: "US",
      sector: "Technology", logo_url: "https://example.com/logo.png"
    ))
    expect(result).to be_success
  end

  it "fails without id" do
    result = contract.call({})
    expect(result).to be_failure
    expect(result.errors[:id]).to be_present
  end

  it "fails with blank name" do
    result = contract.call(valid_params.merge(name: "  "))
    expect(result).to be_failure
    expect(result.errors[:name]).to include("must not be blank")
  end

  it "fails with invalid country code" do
    result = contract.call(valid_params.merge(country: "USA"))
    expect(result).to be_failure
    expect(result.errors[:country]).to include("must be a 2-letter ISO code")
  end

  it "passes with valid 2-letter country code" do
    result = contract.call(valid_params.merge(country: "MX"))
    expect(result).to be_success
  end

  it "fails with non-HTTPS logo URL" do
    result = contract.call(valid_params.merge(logo_url: "http://example.com/logo.png"))
    expect(result).to be_failure
    expect(result.errors[:logo_url]).to include("must be a valid HTTPS URL")
  end

  it "passes with HTTPS logo URL" do
    result = contract.call(valid_params.merge(logo_url: "https://example.com/logo.png"))
    expect(result).to be_success
  end

  it "passes with nil optional fields" do
    result = contract.call(valid_params.merge(name: nil, country: nil, sector: nil, logo_url: nil))
    expect(result).to be_success
  end
end
