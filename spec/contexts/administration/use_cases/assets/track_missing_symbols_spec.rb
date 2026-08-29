require "rails_helper"

RSpec.describe Administration::UseCases::Assets::TrackMissingSymbols do
  let(:user) { create(:user) }

  before { allow(ResolveTrackedSymbolsJob).to receive(:perform_later) }

  # AMD is in the bundled catalogue; ALAB is not. The split is the whole point:
  # one costs nothing and cannot be wrong, the other costs a provider call.
  it "creates the catalogued symbols outright and defers the rest" do
    result = described_class.call(symbols: %w[AMD ALAB], user: user)

    expect(result).to be_success
    expect(result.value!).to eq(created: [ "AMD" ], pending: [ "ALAB" ])
    expect(Asset.find_by(symbol: "AMD")).to have_attributes(name: "Advanced Micro Devices", asset_type: "stock", country: "US")
  end

  it "hands the deferred symbols to the job, and nothing else" do
    described_class.call(symbols: %w[AMD ALAB MSTR], user: user)

    expect(ResolveTrackedSymbolsJob).to have_received(:perform_later).with(%w[ALAB MSTR], user.id)
  end

  it "does not enqueue anything when the catalogue answered everything" do
    described_class.call(symbols: %w[AMD NFLX], user: user)

    expect(ResolveTrackedSymbolsJob).not_to have_received(:perform_later)
  end

  # Re-submitting the same screen must not fail on the contract's uniqueness
  # rule, and must not spend a provider call on a symbol already tracked.
  it "ignores symbols the catalogue already holds" do
    create(:asset, symbol: "ALAB")

    result = described_class.call(symbols: %w[ALAB], user: user)

    expect(result.value!).to eq(created: [], pending: [])
    expect(ResolveTrackedSymbolsJob).not_to have_received(:perform_later)
  end

  it "normalises case and drops duplicates" do
    described_class.call(symbols: [ "amd", "AMD", " amd " ], user: user)

    expect(Asset.where(symbol: "AMD").count).to eq(1)
  end

  it "refuses an empty selection rather than enqueueing nothing" do
    result = described_class.call(symbols: [], user: user)

    expect(result).to be_failure
    expect(result.failure.first).to eq(:validation)
  end
end
