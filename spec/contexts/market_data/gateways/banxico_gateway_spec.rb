require "rails_helper"

RSpec.describe MarketData::Gateways::BanxicoGateway do
  subject(:gateway) { described_class.new(api_key: "test_token") }

  describe "#fetch_auctions" do
    context "when Banxico returns valid data" do
      before { stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026") }

      it "returns Success with parsed auction data" do
        result = gateway.fetch_auctions(term: "28")

        expect(result).to be_success
        data = result.value!
        expect(data.size).to eq(1)
        expect(data.first[:term]).to eq("28")
        expect(data.first[:yield_rate]).to eq(11.15)
        expect(data.first[:price]).to be_a(Float)
        expect(data.first[:auction_date]).to eq(Date.new(2026, 2, 25))
      end
    end

    context "when no auction data returned" do
      before { stub_banxico_not_found(term: "28") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_auctions(term: "28")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_banxico_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_auctions(term: "28")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_banxico_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_auctions(term: "28")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{banxico\.org\.mx/SieAPIRest/service/v1/series/.*/datos/oportuno})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_auctions(term: "28")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "API key resolution" do
    context "when Integration record exists with valid key" do
      before { create(:integration, provider_name: "Banxico", api_key_encrypted: "db_key") }

      it "uses the database key" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "when no Integration record exists" do
      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError, /Banxico/
        )
      end
    end

    context "when Integration exists but api_key_encrypted is nil" do
      before { create(:integration, :keyless, provider_name: "Banxico") }

      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError
        )
      end
    end
  end

  describe "#fetch_all_terms" do
    context "when multiple terms return data" do
      before do
        stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
        stub_banxico_auctions(term: "91", yield_rate: 11.20, date: "25/02/2026")
        stub_banxico_auctions(term: "182", yield_rate: 11.30, date: "25/02/2026")
        stub_banxico_auctions(term: "364", yield_rate: 11.45, date: "25/02/2026")
      end

      it "returns Success with combined auction data" do
        result = gateway.fetch_all_terms

        expect(result).to be_success
        data = result.value!
        expect(data.size).to eq(4)
        expect(data.map { |d| d[:term] }).to contain_exactly("28", "91", "182", "364")
      end
    end
  end
end
