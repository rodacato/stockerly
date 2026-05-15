require "rails_helper"

RSpec.describe MarketData::Queries::MajorIndices do
  describe ".call" do
    it "delegates to MarketIndex.major (ADR-002 supplier-side wrapper)" do
      relation = double("ActiveRecord::Relation")
      includes_relation = double("ActiveRecord::Relation")
      allow(MarketIndex).to receive(:major).and_return(relation)
      allow(relation).to receive(:includes).with(:market_index_histories).and_return(includes_relation)

      expect(described_class.call).to eq(includes_relation)
    end

    it "eager-loads market_index_histories end-to-end" do
      index = create(:market_index, symbol: "SPX")
      result = described_class.call.find { |i| i.symbol == "SPX" }

      expect(result.association(:market_index_histories)).to be_loaded
    end
  end
end
