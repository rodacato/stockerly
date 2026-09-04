require "rails_helper"

RSpec.describe Trading::Domain::TradeDate do
  describe ".fault" do
    it "passes a past date" do
      expect(described_class.fault(90.days.ago.to_date.to_s)).to be_nil
    end

    it "passes today" do
      expect(described_class.fault(Date.current.to_s)).to be_nil
    end

    it "reads a timestamp, not only a date" do
      expect(described_class.fault(2.hours.ago.iso8601)).to be_nil
    end

    it "reports a date the clock cannot read" do
      expect(described_class.fault("no-es-fecha")).to eq(:invalid)
    end

    it "reports a blank string rather than passing it" do
      expect(described_class.fault("")).to eq(:invalid)
    end

    it "reports a date that has not happened" do
      expect(described_class.fault(1.day.from_now.to_date.to_s)).to eq(:future)
    end
  end
end
