require "rails_helper"

RSpec.describe GatewayFailure do
  Response = Struct.new(:status, :body) unless defined?(Response)

  describe ".from" do
    # Before this, every one of these was :gateway_error, so a permanent denial
    # and a transient outage were the same thing to the caller.
    {
      400 => :invalid_request,
      401 => :unauthorized,
      403 => :no_entitlement,
      404 => :not_found,
      410 => :endpoint_retired,
      429 => :rate_limited,
      500 => :gateway_error,
      503 => :gateway_error
    }.each do |status, tag|
      it "maps HTTP #{status} to #{tag}" do
        result = described_class.from(Response.new(status, {}), "Finnhub")

        expect(result.failure[0]).to eq(tag)
      end
    end

    it "keeps the provider's own explanation when it gives one" do
      response = Response.new(403, { "message" => "subscription does not permit querying recent SIP data" })

      expect(described_class.from(response, "Alpaca").failure[1])
        .to include("Alpaca", "no_entitlement", "recent SIP data")
    end

    it "reads DataBursatil's parameter-keyed error map" do
      response = Response.new(400, { "Error" => { "token" => [ "Longitud del token no valida." ] } })

      expect(described_class.from(response, "DataBursatil").failure[1]).to include("Longitud del token")
    end

    it "survives a body that is not a hash" do
      expect(described_class.from(Response.new(500, "Server error"), "FMP").failure[1]).to include("HTTP 500")
    end
  end

  describe ".permanent?" do
    it "treats denials and retired endpoints as permanent" do
      expect(described_class).to be_permanent(:no_entitlement)
      expect(described_class).to be_permanent(:unauthorized)
      expect(described_class).to be_permanent(:endpoint_retired)
    end

    # A rate limit and an outage both clear on their own; retrying is the point.
    it "treats throttling and outages as transient" do
      expect(described_class).not_to be_permanent(:rate_limited)
      expect(described_class).not_to be_permanent(:gateway_error)
      expect(described_class).not_to be_permanent(:not_found)
      expect(described_class).not_to be_permanent(nil)
    end
  end
end
