require "rails_helper"

RSpec.describe MarketData::Domain::VolatilityLevel do
  {
    12 => :calm, 14.99 => :calm, 15 => :normal, 24.9 => :normal,
    25 => :elevated, 34.9 => :elevated, 35 => :high, 80 => :high
  }.each do |value, level|
    it "reads #{value} as #{level}" do
      expect(described_class.for(value)).to eq(level)
    end
  end
end
