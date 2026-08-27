require "rails_helper"

RSpec.describe MarketData::Gateways::BanxicoGateway do
  subject(:gateway) { described_class.new(api_key: "test_token") }

  describe "#fetch_auction_series" do
    let(:from) { Date.new(2026, 1, 1) }
    let(:to)   { Date.new(2026, 2, 1) }

    it "returns every auction in the range, not just the latest" do
      stub_banxico_auction_series(from: from, to: to, auctions: [
        { fecha: "08/01/2026", dato: "10.15" },
        { fecha: "15/01/2026", dato: "10.05" }
      ])

      result = gateway.fetch_auction_series(term: "28", from: from, to: to)

      expect(result).to be_success
      expect(result.value!.map { |a| a[:yield_rate] }).to eq([ 10.15, 10.05 ])
      expect(result.value!.first[:auction_date]).to eq(Date.new(2026, 1, 8))
    end

    it "refuses a term Banxico does not auction" do
      expect(gateway.fetch_auction_series(term: "45", from: from, to: to)).to be_failure
    end

    it "fails rather than raising on a gateway error" do
      stub_request(:get, %r{series/SF43936/datos/}).to_return(status: 500)

      expect(gateway.fetch_auction_series(term: "28", from: from, to: to)).to be_failure
    end
  end

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
      before do
        create(:integration, provider_name: "Banxico", api_key_encrypted: "db_key")
      end

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
    context "when the whole curve comes back" do
      before { stub_banxico_curve }

      it "asks for every term in a single request" do
        gateway.fetch_all_terms

        expect(a_request(:get, %r{series/SF43936,SF43939,SF43942,SF43945/datos/oportuno})).to have_been_made.once
      end

      it "returns Success with combined auction data" do
        result = gateway.fetch_all_terms

        expect(result).to be_success
        expect(result.value!.map { |d| d[:term] }).to contain_exactly("28", "91", "182", "364")
      end

      # Banxico answers in its own order. Matching by position rather than by
      # idSerie would put the 364-day rate on the 28-day row and say nothing.
      it "matches each rate to its own term, not to its position" do
        result = gateway.fetch_all_terms

        rates = result.value!.to_h { |a| [ a[:term], a[:yield_rate] ] }
        expect(rates).to eq("28" => 6.13, "91" => 6.60, "182" => 6.72, "364" => 7.06)
      end

      it "spends one call against the provider, not four" do
        allow(RateLimiter).to receive(:check!).and_call_original

        gateway.fetch_all_terms

        expect(RateLimiter).to have_received(:check!).with("Banxico").once
      end
    end
  end
end
