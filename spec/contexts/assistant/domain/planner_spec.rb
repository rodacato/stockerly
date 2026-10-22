require "rails_helper"

# What survives of a model's choice: registry names only, declared inputs only,
# a bounded plan (plan §4, gate G2).
RSpec.describe Assistant::Domain::Planner do
  def reply(*reads) = reads.to_json

  it "describes exactly the registry to the model, with each read's inputs" do
    system = described_class.system(nil)

    Assistant::Capabilities::Registry.available(holdings: false).each_key { |name| expect(system).to include("- #{name}:") }
    expect(system).to include("symbol: the ticker")
  end

  it "lists the holdings reads only with the owner's switch on" do
    expect(described_class.system(nil)).not_to include("- portfolio.")
    expect(described_class.system(nil, holdings: true)).to include("- portfolio.positions:", "- portfolio.events:")
  end

  it "keeps a holdings read only with the switch on" do
    reply = reply({ read: "portfolio.positions" }, { read: "portfolio.events" })

    expect(described_class.steps(reply)).to eq([])
    expect(described_class.steps(reply, holdings: true)).to eq([ [ "portfolio.positions", {} ], [ "portfolio.events", {} ] ])
  end

  it "turns the reply into registry steps" do
    steps = described_class.steps(reply({ read: "asset.indicators", symbol: "nvda", only: %w[rsi] }, { read: "glossary.define", term: "RSI" }))

    expect(steps).to eq([ [ "asset.indicators", { symbol: "NVDA", only: %w[rsi] } ], [ "glossary.define", { term: "RSI" } ] ])
  end

  it "reads the array out of prose or a code fence around it" do
    steps = described_class.steps("Claro:\n```json\n#{reply({ read: 'asset.quote', symbol: 'NVDA' })}\n```")

    expect(steps).to eq([ [ "asset.quote", { symbol: "NVDA" } ] ])
  end

  it "drops a name the registry does not list" do
    steps = described_class.steps(reply({ read: "portfolio.positions", symbol: "NVDA" }, { read: "asset.quote", symbol: "NVDA" }))

    expect(steps.map(&:first)).to eq(%w[asset.quote])
  end

  it "keeps only the inputs a capability can declare, and caps their size" do
    step = described_class.steps(reply({ read: "glossary.define", term: "x" * 500, sql: "drop table" })).sole

    expect(step.last.keys).to eq([ :term ])
    expect(step.last[:term].length).to eq(described_class::MAX_INPUT)
  end

  it "plans at most six reads, and no read twice" do
    reads = Array.new(10) { |index| { read: "asset.quote", symbol: "S#{index}" } }

    expect(described_class.steps(reply(*reads)).size).to eq(described_class::MAX_STEPS)
    expect(described_class.steps(reply({ read: "asset.quote", symbol: "A" }, { read: "asset.quote", symbol: "a" })).size).to eq(1)
  end

  it "reads anything but a JSON array of objects as no plan" do
    [ "No sé.", "{\"read\": \"asset.quote\"}", "[1, 2]", "[{\"read\": ", "] [", "[" * 50_000 ].each do |text|
      expect(described_class.steps(text)).to eq([])
    end
  end

  it "tells the model the screen's symbol, and nothing when there is none" do
    expect(described_class.system("NVDA")).to end_with("Screen symbol: NVDA.")
    expect(described_class.system(nil)).not_to include("Screen symbol")
  end
  it "tells the model today's date and which reads take no input" do
    system = described_class.system(nil)

    expect(system).to include("Today: #{Date.current.iso8601}.")
    expect(system).to match(/- market\.pulse: .* Inputs: none\./)
  end

  it "passes a date only to a read that declares one" do
    steps = described_class.steps(reply({ read: "fx.rate", date: "2026-05-03" }, { read: "asset.quote", symbol: "NVDA", date: "2026-05-03" }))

    expect(steps).to eq([ [ "fx.rate", { date: "2026-05-03" } ], [ "asset.quote", { symbol: "NVDA" } ] ])
  end

  it "tells the model what the user's screen shows, and nothing for an unknown one" do
    expect(described_class.system(nil, screen: "senales")).to include("User's screen: Señales:")
    expect(described_class.system(nil, screen: "nope")).not_to include("User's screen")
  end
end
