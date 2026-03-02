require "rails_helper"

RSpec.describe Alerts::Contracts::CreateContract do
  subject { described_class.new }

  let(:valid_params) { { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }

  describe "validation" do
    it "passes with valid params" do
      result = subject.call(valid_params)
      expect(result).to be_success
    end

    it "fails when asset_symbol is missing" do
      result = subject.call(valid_params.merge(asset_symbol: ""))
      expect(result).to be_failure
      expect(result.errors[:asset_symbol]).to be_present
    end

    it "fails when condition is invalid" do
      result = subject.call(valid_params.merge(condition: "invalid_condition"))
      expect(result).to be_failure
      expect(result.errors[:condition]).to be_present
    end

    it "fails when threshold_value is missing" do
      result = subject.call(valid_params.except(:threshold_value))
      expect(result).to be_failure
      expect(result.errors[:threshold_value]).to be_present
    end

    %w[price_crosses_above price_crosses_below day_change_percent rsi_overbought rsi_oversold sentiment_above sentiment_below volume_spike].each do |condition|
      it "accepts condition '#{condition}'" do
        result = subject.call(valid_params.merge(condition: condition))
        expect(result).to be_success
      end
    end
  end
end
