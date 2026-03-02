require "rails_helper"

RSpec.describe Trading::Handlers::AdjustPositionsOnSplit do
  describe ".async?" do
    it "returns true" do
      expect(described_class.async?).to be true
    end
  end

  describe ".call" do
    it "invokes Trading::Domain::SplitAdjuster for the split" do
      split = create(:stock_split)
      adjuster = instance_double(Trading::Domain::SplitAdjuster, adjust!: nil)
      allow(Trading::Domain::SplitAdjuster).to receive(:new).with(split).and_return(adjuster)

      described_class.call(stock_split_id: split.id)

      expect(adjuster).to have_received(:adjust!)
    end

    it "does nothing when split not found" do
      expect { described_class.call(stock_split_id: 0) }.not_to raise_error
    end
  end
end
