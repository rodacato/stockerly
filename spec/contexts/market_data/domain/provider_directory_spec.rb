require "rails_helper"

RSpec.describe MarketData::Domain::ProviderDirectory do
  describe ".for" do
    it "marks a key-requiring provider with an https site and requires_key: true" do
      info = described_class.for("Alpaca")
      expect(info.description).to be_present
      expect(info.url).to start_with("https://")
      expect(info.requires_key).to be(true)
    end

    it "marks a public provider with a source link and requires_key: false" do
      info = described_class.for("Alternative.me")
      expect(info.description).to be_present
      expect(info.url).to start_with("https://")
      expect(info.requires_key).to be(false)
    end

    it "returns nil for an unknown provider" do
      expect(described_class.for("Not A Provider")).to be_nil
    end

    it "has an entry for every provider the first-boot setup creates" do
      # Drift guard: an Integration created in CreateFirstAdmin with no directory
      # entry would render an onboarding card with no description or source link.
      created = Rails.root.join("app/contexts/identity/use_cases/create_first_admin.rb").read
                    .scan(/provider_name: "([^"]+)"/).flatten.uniq
      missing = created.reject { |name| described_class.for(name) }
      expect(missing).to be_empty, "providers with no ProviderDirectory entry: #{missing.inspect}"
    end
  end
end
