require "rails_helper"

RSpec.describe Trading::Domain::FxDegradation do
  subject(:fx) { described_class.new }

  it "returns the figure when it can be computed" do
    expect(fx.figure { 42 }).to eq(42)
  end

  it "reports nothing degraded until something does" do
    fx.figure { 42 }

    expect(fx).not_to be_degraded
  end

  it "absents a figure it cannot convert" do
    expect(fx.figure { raise Trading::Domain::MissingFxRate }).to be_nil
  end

  it "never answers a missing rate with a zero" do
    expect(fx.figure { raise Trading::Domain::MissingFxRate }).not_to eq(0)
  end

  it "lets a collection absent itself as empty rather than nil" do
    expect(fx.figure({}) { raise Trading::Domain::MissingFxRate }).to eq({})
  end

  it "remembers, so the screen can say why the figure is missing" do
    fx.figure { raise Trading::Domain::MissingFxRate }

    expect(fx).to be_degraded
  end

  it "stays degraded once it has degraded, whatever follows" do
    fx.figure { raise Trading::Domain::MissingFxRate }
    fx.figure { 42 }

    expect(fx).to be_degraded
  end

  it "does not swallow anything else" do
    expect { fx.figure { raise ArgumentError, "unrelated" } }.to raise_error(ArgumentError)
  end
end
