require "rails_helper"

RSpec.describe Identity::Domain::RecoveryCodes do
  describe ".generate" do
    it "mints ten codes in the shape the artboard prints" do
      codes = described_class.generate

      expect(codes.size).to eq(10)
      expect(codes).to all(match(/\A[0-9a-f]{4}-[0-9a-f]{4}\z/))
    end

    it "does not repeat itself across calls" do
      expect(described_class.generate & described_class.generate).to be_empty
    end
  end

  describe ".normalize" do
    it "forgives the mistakes a reader typing from paper actually makes" do
      %w[7f2a-91c4 7F2A91C4].each { |input| expect(described_class.normalize(input)).to eq("7f2a91c4") }
      expect(described_class.normalize("  7f2a 91c4 ")).to eq("7f2a91c4")
    end

    it "strips anything that is not a code character" do
      expect(described_class.normalize("7f2a/91c4!")).to eq("7f2a91c4")
    end
  end

  describe ".digest and .matches?" do
    it "matches the code it was made from, normalization included" do
      digest = described_class.digest("7f2a-91c4")

      expect(described_class.matches?("7F2A 91C4", digest)).to be true
      expect(described_class.matches?("dead-beef", digest)).to be false
    end

    it "never stores the code itself" do
      expect(described_class.digest("7f2a-91c4")).not_to include("7f2a")
    end

    it "answers false rather than raising on a corrupt digest" do
      expect(described_class.matches?("7f2a-91c4", "not-a-bcrypt-hash")).to be false
    end
  end
end
