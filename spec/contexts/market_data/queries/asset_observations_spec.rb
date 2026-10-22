require "rails_helper"

RSpec.describe MarketData::Queries::AssetObservations do
  let!(:asset) { create(:asset, symbol: "AAPL") }

  def ar_records_in(value)
    case value
    when ActiveRecord::Base then [ value ]
    when Hash then value.flat_map { |key, nested| ar_records_in(key) + ar_records_in(nested) }
    when Array then value.flat_map { |nested| ar_records_in(nested) }
    else []
    end
  end

  context "with observations on file" do
    let(:newest) { 1.day.ago.change(usec: 0) }
    let(:older) { 2.days.ago.change(usec: 0) }

    before do
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_exited",
                                     observed_at: newest)
      create(:technical_observation, asset: asset, observation_type: "ma50_crossed_above",
                                     observed_at: older)
      create(:technical_observation, asset: asset, observation_type: "bb_upper_breached",
                                     observed_at: 31.days.ago)
      create(:technical_observation, observation_type: "rsi_overbought_entered")
    end

    it "returns the page's window, newest first, with the page's phrase and the verb's label" do
      result = described_class.call(symbol: "aapl")

      expect(result).to eq(
        symbol: "AAPL",
        observations: [
          { type: "rsi_oversold_exited", observed_at: newest,
            reading: MarketData::Domain::ObservationPhrases.for("rsi_oversold_exited"), action: nil },
          { type: "ma50_crossed_above", observed_at: older,
            reading: "cruzó al alza su MA50", action: "compra" }
        ]
      )
    end

    it "stops at the limit" do
      expect(described_class.call(symbol: "AAPL", limit: 1)[:observations].pluck(:type)).to eq([ "rsi_oversold_exited" ])
    end

    it "holds no ActiveRecord object anywhere in the structure" do
      expect(ar_records_in(described_class.call(symbol: "AAPL"))).to be_empty
    end
  end

  it "returns nil for a symbol the catalogue does not carry" do
    expect(described_class.call(symbol: "NOPE")).to be_nil
  end

  it "has no observations when none were persisted" do
    expect(described_class.call(symbol: "AAPL")).to eq(symbol: "AAPL", observations: [])
  end
end
