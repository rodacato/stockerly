require "rails_helper"

RSpec.describe Trading::Handlers::AdjustPositionsOnSplit do
  let(:facts) { { asset_id: 7, ex_date: Date.new(2026, 2, 15), ratio_from: 1, ratio_to: 4 } }

  describe ".async?" do
    it "returns true" do
      expect(described_class.async?).to be true
    end
  end

  describe ".call" do
    it "invokes Trading::Domain::SplitAdjuster with the event's facts" do
      adjuster = instance_double(Trading::Domain::SplitAdjuster, adjust!: nil)
      allow(Trading::Domain::SplitAdjuster).to receive(:new).with(**facts).and_return(adjuster)

      described_class.call(facts)

      expect(adjuster).to have_received(:adjust!)
    end

    it "reads the facts off a published event too" do
      adjuster = instance_double(Trading::Domain::SplitAdjuster, adjust!: nil)
      allow(Trading::Domain::SplitAdjuster).to receive(:new).with(**facts).and_return(adjuster)

      described_class.call(Trading::Events::SplitDetected.new(**facts))

      expect(adjuster).to have_received(:adjust!)
    end

    # What a job enqueued before the event changed shape looks like on arrival.
    it "does nothing when the payload carries no facts" do
      allow(Trading::Domain::SplitAdjuster).to receive(:new)

      described_class.call(stock_split_id: 5)

      expect(Trading::Domain::SplitAdjuster).not_to have_received(:new)
    end
  end
end
