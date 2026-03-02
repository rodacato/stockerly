require "rails_helper"

RSpec.describe MarketHours do
  include ActiveSupport::Testing::TimeHelpers

  describe ".us_market_open?" do
    it "returns true during trading hours on weekdays" do
      # Wednesday at 10:00 AM ET
      travel_to Time.zone.parse("2025-01-15 10:00:00 EST") do
        expect(described_class.us_market_open?).to be true
      end
    end

    it "returns true at exactly 9:30 AM ET (market open)" do
      travel_to Time.zone.parse("2025-01-15 09:30:00 EST") do
        expect(described_class.us_market_open?).to be true
      end
    end

    it "returns false at 9:29 AM ET (one minute before open)" do
      travel_to Time.zone.parse("2025-01-15 09:29:00 EST") do
        expect(described_class.us_market_open?).to be false
      end
    end

    it "returns false at 4:00 PM ET (market close)" do
      travel_to Time.zone.parse("2025-01-15 16:00:00 EST") do
        expect(described_class.us_market_open?).to be false
      end
    end

    it "returns true at 3:59 PM ET (one minute before close)" do
      travel_to Time.zone.parse("2025-01-15 15:59:00 EST") do
        expect(described_class.us_market_open?).to be true
      end
    end

    it "returns false on Saturday" do
      travel_to Time.zone.parse("2025-01-18 12:00:00 EST") do
        expect(described_class.us_market_open?).to be false
      end
    end

    it "returns false on Sunday" do
      travel_to Time.zone.parse("2025-01-19 12:00:00 EST") do
        expect(described_class.us_market_open?).to be false
      end
    end

    it "returns false late at night" do
      travel_to Time.zone.parse("2025-01-15 23:00:00 EST") do
        expect(described_class.us_market_open?).to be false
      end
    end
  end

  describe ".bmv_market_open?" do
    it "returns true during BMV trading hours on weekdays" do
      # Wednesday at 10:00 AM Mexico City
      travel_to Time.zone.parse("2025-01-15 10:00:00 CST") do
        expect(described_class.bmv_market_open?).to be true
      end
    end

    it "returns true at exactly 8:30 AM CST (market open)" do
      travel_to Time.zone.parse("2025-01-15 08:30:00 CST") do
        expect(described_class.bmv_market_open?).to be true
      end
    end

    it "returns false at 8:29 AM CST (one minute before open)" do
      travel_to Time.zone.parse("2025-01-15 08:29:00 CST") do
        expect(described_class.bmv_market_open?).to be false
      end
    end

    it "returns false at 3:00 PM CST (market close)" do
      travel_to Time.zone.parse("2025-01-15 15:00:00 CST") do
        expect(described_class.bmv_market_open?).to be false
      end
    end

    it "returns false on weekends" do
      travel_to Time.zone.parse("2025-01-18 12:00:00 CST") do
        expect(described_class.bmv_market_open?).to be false
      end
    end
  end

  describe ".crypto_market_open?" do
    it "always returns true" do
      travel_to Time.zone.parse("2025-01-18 03:00:00 UTC") do
        expect(described_class.crypto_market_open?).to be true
      end
    end
  end

  describe ".open?" do
    it "checks US market for NYSE exchange" do
      travel_to Time.zone.parse("2025-01-15 12:00:00 EST") do
        expect(described_class.open?("NYSE")).to be true
      end
    end

    it "checks US market for NASDAQ exchange" do
      travel_to Time.zone.parse("2025-01-15 12:00:00 EST") do
        expect(described_class.open?("NASDAQ")).to be true
      end
    end

    it "checks BMV market for BMV exchange" do
      travel_to Time.zone.parse("2025-01-15 12:00:00 CST") do
        expect(described_class.open?("BMV")).to be true
      end
    end

    it "returns true for unknown exchanges" do
      expect(described_class.open?("UNKNOWN")).to be true
    end

    it "returns true for blank exchange" do
      expect(described_class.open?(nil)).to be true
      expect(described_class.open?("")).to be true
    end

    it "is case insensitive" do
      travel_to Time.zone.parse("2025-01-15 12:00:00 EST") do
        expect(described_class.open?("nyse")).to be true
        expect(described_class.open?("nasdaq")).to be true
      end
    end
  end

  describe ".open_for_asset?" do
    it "returns true for crypto assets regardless of time" do
      asset = build(:asset, :crypto)

      travel_to Time.zone.parse("2025-01-18 03:00:00 UTC") do
        expect(described_class.open_for_asset?(asset)).to be true
      end
    end

    it "checks US market for stock assets on NYSE" do
      asset = build(:asset, asset_type: :stock, exchange: "NYSE")

      travel_to Time.zone.parse("2025-01-18 12:00:00 EST") do
        expect(described_class.open_for_asset?(asset)).to be false
      end
    end

    it "checks BMV market for Mexican assets" do
      asset = build(:asset, :mexican, asset_type: :stock, exchange: "BMV")

      travel_to Time.zone.parse("2025-01-15 12:00:00 CST") do
        expect(described_class.open_for_asset?(asset)).to be true
      end
    end
  end
end
