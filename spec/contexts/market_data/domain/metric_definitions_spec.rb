require "rails_helper"

RSpec.describe MarketData::Domain::MetricDefinitions do
  describe ".all" do
    it "returns all registered definitions" do
      expect(described_class.all).not_to be_empty
      expect(described_class.all.first).to be_a(MarketData::Domain::MetricDefinitions::Definition)
    end

    it "has at least 30 definitions" do
      expect(described_class.all.size).to be >= 30
    end
  end

  describe ".find" do
    it "returns a definition by key" do
      definition = described_class.find(:pe_ratio)
      expect(definition.key).to eq(:pe_ratio)
      expect(definition.display_name).to eq("P/E Ratio")
      expect(definition.category).to eq(:valuation)
    end

    it "raises KeyError for unknown metric" do
      expect { described_class.find(:unknown_metric) }.to raise_error(KeyError, /Unknown metric/)
    end
  end

  describe ".by_category" do
    it "returns definitions filtered by category" do
      valuation = described_class.by_category(:valuation)
      expect(valuation).to all(have_attributes(category: :valuation))
      expect(valuation.size).to be >= 5
    end

    it "returns results sorted by display_order" do
      valuation = described_class.by_category(:valuation)
      orders = valuation.map(&:display_order)
      expect(orders).to eq(orders.sort)
    end

    it "returns empty array for unknown category" do
      expect(described_class.by_category(:nonexistent)).to be_empty
    end
  end

  describe ".categories" do
    it "returns all unique categories" do
      categories = described_class.categories
      expect(categories).to include(:valuation, :profitability, :health, :growth, :dividends, :risk, :identity)
    end
  end

  describe "definition completeness" do
    it "every definition has all required fields" do
      described_class.all.each do |defn|
        expect(defn.key).to be_a(Symbol), "Missing key for #{defn.inspect}"
        expect(defn.category).to be_a(Symbol), "Missing category for #{defn.key}"
        expect(defn.display_name).to be_present, "Missing display_name for #{defn.key}"
        expect(defn.short_desc).to be_present, "Missing short_desc for #{defn.key}"
        expect(defn.context_guidance).to be_present, "Missing context_guidance for #{defn.key}"
        expect(defn.format_type).to be_present, "Missing format_type for #{defn.key}"
        expect(defn.display_order).to be_a(Integer), "Missing display_order for #{defn.key}"
        expect(defn.icon).to be_present, "Missing icon for #{defn.key}"
      end
    end

    it "has no duplicate keys" do
      keys = described_class.all.map(&:key)
      expect(keys.uniq.size).to eq(keys.size)
    end
  end
end
