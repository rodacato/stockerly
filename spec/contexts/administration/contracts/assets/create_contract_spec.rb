require "rails_helper"

RSpec.describe Administration::Contracts::Assets::CreateContract do
  subject(:contract) { described_class.new }

  let(:valid_params) do
    { symbol: "MSFT", name: "Microsoft Corporation", asset_type: "stock" }
  end

  it "passes with valid required params" do
    result = contract.call(valid_params)
    expect(result).to be_success
  end

  it "passes with all optional params" do
    result = contract.call(valid_params.merge(
      country: "US", exchange: "NASDAQ", sector: "Technology",
      logo_url: "https://logo.clearbit.com/microsoft.com"
    ))
    expect(result).to be_success
  end

  it "fails with missing symbol" do
    result = contract.call(valid_params.merge(symbol: ""))
    expect(result).to be_failure
    expect(result.errors[:symbol]).to be_present
  end

  it "fails with missing name" do
    result = contract.call(valid_params.merge(name: ""))
    expect(result).to be_failure
    expect(result.errors[:name]).to be_present
  end

  it "fails with missing asset_type" do
    result = contract.call(valid_params.merge(asset_type: ""))
    expect(result).to be_failure
    expect(result.errors[:asset_type]).to be_present
  end

  it "fails with invalid asset_type" do
    result = contract.call(valid_params.merge(asset_type: "commodity"))
    expect(result).to be_failure
    expect(result.errors[:asset_type]).to be_present
  end

  it "accepts all valid asset types" do
    %w[stock crypto index etf].each do |type|
      result = contract.call(valid_params.merge(asset_type: type))
      expect(result).to be_success, "expected #{type} to be valid"
    end
  end

  it "fails with lowercase symbol" do
    result = contract.call(valid_params.merge(symbol: "msft"))
    expect(result).to be_failure
    expect(result.errors[:symbol]).to include("must be 1-20 uppercase alphanumeric characters")
  end

  it "fails with symbol longer than 20 characters" do
    result = contract.call(valid_params.merge(symbol: "A" * 21))
    expect(result).to be_failure
    expect(result.errors[:symbol]).to include("must be 1-20 uppercase alphanumeric characters")
  end

  it "allows dots, hyphens and slashes in symbol" do
    result = contract.call(valid_params.merge(symbol: "BRK.A"))
    expect(result).to be_success
  end

  it "fails with duplicate symbol" do
    create(:asset, symbol: "MSFT")
    result = contract.call(valid_params)
    expect(result).to be_failure
    expect(result.errors[:symbol]).to include("already exists")
  end

  it "fails with invalid country code" do
    result = contract.call(valid_params.merge(country: "USA"))
    expect(result).to be_failure
    expect(result.errors[:country]).to include("must be a 2-letter ISO code")
  end

  it "passes with valid 2-letter country code" do
    result = contract.call(valid_params.merge(country: "US"))
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

  it "passes with blank optional fields" do
    result = contract.call(valid_params.merge(country: nil, exchange: nil, sector: nil, logo_url: nil))
    expect(result).to be_success
  end
end
