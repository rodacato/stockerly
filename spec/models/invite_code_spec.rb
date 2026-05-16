require "rails_helper"

RSpec.describe InviteCode, type: :model do
  describe "validations" do
    subject { build(:invite_code) }

    it { is_expected.to be_valid }

    it "requires a code" do
      subject.code = nil
      expect(subject).not_to be_valid
    end

    it "enforces unique code" do
      existing = create(:invite_code)
      duplicate = build(:invite_code, code: existing.code)
      expect(duplicate).not_to be_valid
    end

    it "requires 12 hex characters after normalization" do
      subject.code = "not-hex-123!"
      expect(subject).not_to be_valid
    end

    it "accepts hyphenated input and normalizes" do
      subject.code = "a3f8-9c2e-4b1d"
      subject.valid?
      expect(subject.code).to eq("a3f89c2e4b1d")
    end

    it "accepts uppercase and normalizes to lowercase" do
      subject.code = "A3F89C2E4B1D"
      subject.valid?
      expect(subject.code).to eq("a3f89c2e4b1d")
    end
  end

  describe "scopes" do
    it ".unused returns only codes without used_at" do
      unused = create(:invite_code)
      _used  = create(:invite_code, :used)
      expect(InviteCode.unused).to contain_exactly(unused)
    end

    it ".used returns only codes with used_at" do
      _unused = create(:invite_code)
      used    = create(:invite_code, :used)
      expect(InviteCode.used).to contain_exactly(used)
    end
  end

  describe ".normalize" do
    it "strips hyphens, underscores, spaces" do
      expect(InviteCode.normalize("a3f8-9c2e_4b1d")).to eq("a3f89c2e4b1d")
      expect(InviteCode.normalize("a3f8 9c2e 4b1d")).to eq("a3f89c2e4b1d")
    end

    it "downcases" do
      expect(InviteCode.normalize("A3F89C2E4B1D")).to eq("a3f89c2e4b1d")
    end

    it "returns nil for nil input" do
      expect(InviteCode.normalize(nil)).to be_nil
    end
  end

  describe ".generate_code" do
    it "returns 12 hex characters" do
      code = InviteCode.generate_code
      expect(code).to match(/\A[a-f0-9]{12}\z/)
    end

    it "returns different codes on subsequent calls" do
      expect(InviteCode.generate_code).not_to eq(InviteCode.generate_code)
    end
  end

  describe "#used?" do
    it "returns false when used_at is nil" do
      expect(build(:invite_code).used?).to be false
    end

    it "returns true when used_at is present" do
      expect(build(:invite_code, :used).used?).to be true
    end
  end

  describe "#formatted_code" do
    it "groups in 4-character chunks separated by hyphens" do
      invite = build(:invite_code, code: "a3f89c2e4b1d")
      expect(invite.formatted_code).to eq("a3f8-9c2e-4b1d")
    end
  end
end
