require "rails_helper"

RSpec.describe Alerts::Domain::RuleSuggestions do
  def holding(symbol, type, value)
    { symbol: symbol, asset_type: type, market_value: value, shares: 12 }
  end

  let(:aapl)  { holding("AAPL", "stock", 38_000) }
  let(:nvda)  { holding("NVDA", "stock", 12_000) }
  let(:cetes) { holding("CETES28", "fixed_income", 50_000) }

  describe "the shape it returns" do
    it "suggests a day-move rule on the position that moves the portfolio most" do
      suggestions = described_class.call(holdings: [ nvda, aapl ])

      day_move = suggestions.find { |s| s.condition == "day_change_percent" }
      expect(day_move.asset_symbol).to eq("AAPL")
      expect(day_move.threshold_value).to eq(5)
    end

    it "puts the RSI rule on a different holding, so two indicators are taught" do
      suggestions = described_class.call(holdings: [ aapl, nvda ])

      expect(suggestions.map { |s| [ s.condition, s.asset_symbol ] })
        .to include([ "day_change_percent", "AAPL" ], [ "rsi_overbought", "NVDA" ])
    end

    it "suggests the CETES auction window when fixed income is held" do
      suggestions = described_class.call(holdings: [ aapl, cetes ])

      cete = suggestions.find { |s| s.condition == "cete_auction" }
      expect(cete.asset_symbol).to eq("CETES28")
      expect(cete.window_days).to eq(3)
      expect(cete.threshold_value).to be_nil
    end

    it "carries no copy — only the rule's shape and the context that justifies it" do
      suggestion = described_class.call(holdings: [ aapl ]).first

      expect(suggestion.to_h.keys)
        .to contain_exactly(:condition, :asset_symbol, :threshold_value, :window_days, :shares)
    end
  end

  describe "what it declines to suggest" do
    it "returns nothing when there are no holdings" do
      expect(described_class.call(holdings: [])).to be_empty
    end

    it "never suggests a technical rule for fixed income, which has no RSI" do
      suggestions = described_class.call(holdings: [ cetes ])

      expect(suggestions.map(&:condition)).to eq([ "cete_auction" ])
    end

    it "skips a suggestion the owner already has a rule for" do
      existing = [ { condition: "day_change_percent", asset_symbol: "aapl" } ]

      suggestions = described_class.call(holdings: [ aapl ], existing_rules: existing)

      expect(suggestions.map(&:condition)).not_to include("day_change_percent")
    end

    it "matches an existing rule regardless of how its symbol was cased" do
      existing = [ { condition: "rsi_overbought", asset_symbol: "NvDa" } ]

      suggestions = described_class.call(holdings: [ aapl, nvda ], existing_rules: existing)

      expect(suggestions.map { |s| [ s.condition, s.asset_symbol ] })
        .not_to include([ "rsi_overbought", "NVDA" ])
    end

    it "returns at most three, so the block never becomes a list to triage" do
      many = (1..9).map { |i| holding("SYM#{i}", "stock", i * 1_000) }

      expect(described_class.call(holdings: many + [ cetes ]).size).to be <= 3
    end
  end
end
