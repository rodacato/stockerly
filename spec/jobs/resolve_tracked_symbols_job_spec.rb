require "rails_helper"

RSpec.describe ResolveTrackedSymbolsJob do
  let(:user) { create(:user) }
  let!(:integration) { create(:integration, provider_name: "Yahoo Finance", max_requests_per_minute: 30, daily_call_limit: 2_000) }

  def stub_match(symbol, name: "#{symbol} Inc.", exchange: "NASDAQ")
    stub_yfinance_search(symbol, results: [ yfinance_match(symbol: symbol, name: name, exchange: exchange) ])
  end

  it "adds what the provider recognises, with the metadata it returned" do
    stub_match("ALAB", name: "Astera Labs, Inc.")

    described_class.perform_now([ "ALAB" ], user.id)

    expect(Asset.find_by(symbol: "ALAB")).to have_attributes(name: "Astera Labs, Inc.", country: "US", asset_type: "stock")
  end

  # The refusal the screen's own copy promises: a bare ticker never becomes an
  # asset on a near miss, because a junk row syncs forever.
  it "refuses a result whose symbol is not the one asked for" do
    stub_yfinance_search("ALAB", results: [ yfinance_match(symbol: "ALAB.MX", name: "Astera Labs") ])

    described_class.perform_now([ "ALAB" ], user.id)

    expect(Asset.where(symbol: [ "ALAB", "ALAB.MX" ])).to be_empty
  end

  it "notifies once with what landed and what did not" do
    stub_match("ALAB")
    stub_yfinance_search("ZZZZ", results: [])

    described_class.perform_now(%w[ALAB ZZZZ], user.id)

    notification = user.notifications.last
    expect(notification.title).to eq("Di de alta 1 símbolo de tu archivo")
    expect(notification.body).to include("ALAB").and include("ZZZZ")
  end

  # Hitting the per-minute ceiling is pacing, not failure. The batch continues
  # later and the tally rides along so one notification covers the whole run.
  it "re-enqueues the remainder when the provider ceiling is spent" do
    stub_match("ALAB")
    integration.update!(minute_calls: 30, minute_reset_at: Time.current)

    expect(described_class).to receive(:set).with(wait: described_class::RETRY_IN).and_return(described_class)
    expect(described_class).to receive(:perform_later).with([ "ALAB" ], user.id, [], [])

    described_class.perform_now([ "ALAB" ], user.id)

    expect(user.notifications).to be_empty
  end

  it "carries an earlier pass's tally into the notification" do
    stub_yfinance_search("ZZZZ", results: [])

    described_class.perform_now([ "ZZZZ" ], user.id, [ "AMD" ], [])

    expect(user.notifications.last.title).to eq("Di de alta 1 símbolo de tu archivo")
    expect(user.notifications.last.body).to include("AMD").and include("ZZZZ")
  end

  it "does nothing when the user is gone" do
    expect { described_class.perform_now([ "ALAB" ], 0) }.not_to change(Asset, :count)
  end
end
