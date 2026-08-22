require "rails_helper"

RSpec.describe MarketData::Domain::ProviderDirectory do
  describe ".for" do
    it "returns a description and https signup_url for a key-requiring provider" do
      info = described_class.for("Polygon.io")
      expect(info.description).to be_present
      expect(info.signup_url).to start_with("https://")
    end

    it "returns a description but no signup_url for a public provider" do
      info = described_class.for("Yahoo Finance")
      expect(info.description).to be_present
      expect(info.signup_url).to be_nil
    end

    it "returns nil for an unknown provider" do
      expect(described_class.for("Not A Provider")).to be_nil
    end

    it "has an entry for every provider the first-boot setup creates" do
      # Drift guard: an Integration created in CreateFirstAdmin with no directory
      # entry would render an onboarding card with no description or signup link.
      created = File.read(Rails.root.join("app/contexts/identity/use_cases/create_first_admin.rb"))
                    .scan(/provider_name: "([^"]+)"/).flatten.uniq
      missing = created.reject { |name| described_class.for(name) }
      expect(missing).to be_empty, "providers with no ProviderDirectory entry: #{missing.inspect}"
    end
  end
end
