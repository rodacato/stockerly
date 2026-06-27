require "rails_helper"

RSpec.describe TechnicalObservation, type: :model do
  describe "validations" do
    it "requires observation_type" do
      observation = build(:technical_observation, observation_type: nil)
      expect(observation).not_to be_valid
      expect(observation.errors[:observation_type]).to be_present
    end

    it "requires observed_at" do
      observation = build(:technical_observation, observed_at: nil)
      expect(observation).not_to be_valid
      expect(observation.errors[:observed_at]).to be_present
    end

    it "rejects unknown observation_type values" do
      observation = build(:technical_observation, observation_type: "made_up_thing")
      expect(observation).not_to be_valid
      expect(observation.errors[:observation_type]).to be_present
    end

    described_class::TYPES.each do |type|
      it "accepts canonical type :#{type}" do
        observation = build(:technical_observation, observation_type: type)
        expect(observation).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:asset) { create(:asset, symbol: "AAPL") }
    let!(:recent) { create(:technical_observation, asset: asset, observed_at: 2.days.ago) }
    let!(:old) { create(:technical_observation, asset: asset, observed_at: 30.days.ago) }

    it ".recent orders by observed_at DESC" do
      expect(described_class.recent.first).to eq(recent)
    end

    it ".within_last(N) filters to recent N days" do
      expect(described_class.within_last(7)).to contain_exactly(recent)
    end

    it ".for_assets filters by asset_id list" do
      other = create(:technical_observation, asset: create(:asset, symbol: "MSFT"))
      expect(described_class.for_assets([ asset.id ])).to contain_exactly(recent, old)
      expect(described_class.for_assets([ asset.id ])).not_to include(other)
    end
  end
end
