require "rails_helper"

RSpec.describe Trading::UseCases::SearchCatalogue do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def search(query) = described_class.call(user: user, query: query)

  it "finds an asset by symbol or by name, ignoring case" do
    alab = create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.")
    create(:asset, :stock, symbol: "MSFT", name: "Microsoft")

    expect(search("alab").pluck(:asset)).to eq([ alab ])
    expect(search("astera").pluck(:asset)).to eq([ alab ])
  end

  it "labels each result with the tier it sits on" do
    held = create(:asset, :stock, symbol: "ABNB", name: "Airbnb")
    followed = create(:asset, :stock, symbol: "ALAB", name: "Astera Labs")
    create(:asset, :stock, symbol: "ABT", name: "Abbott")
    create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
    create(:watchlist_item, user: user, asset: followed)

    expect(search("ab").to_h { [ _1[:asset].symbol, _1[:tier] ] })
      .to eq("ABNB" => :held, "ALAB" => :followed, "ABT" => :tracked)
  end

  # The symbol typed exactly is the one wanted, even when a held asset's name
  # also contains it.
  it "puts the exact symbol first, then Holdings, Watchlist and Tracked" do
    held = create(:asset, :stock, symbol: "GOOGL", name: "Alphabet Class A")
    followed = create(:asset, :stock, symbol: "ALPH", name: "Alpha Tau")
    exact = create(:asset, :stock, symbol: "ALP", name: "Alpine")
    create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 1, status: :open)
    create(:watchlist_item, user: user, asset: followed)

    expect(search("alp").map { _1[:asset].symbol }).to eq([ exact.symbol, held.symbol, followed.symbol ])
  end

  it "carries the day change computed from the last two closes (ADR-021)" do
    asset = create(:asset, :stock, symbol: "ALAB", name: "Astera Labs")
    create(:asset_price_history, asset: asset, date: 2.days.ago.to_date, close: 100)
    create(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 102)

    expect(search("alab").first[:change]).to eq(2)
  end

  it "leaves the day change empty when there is nothing to compare" do
    create(:asset, :stock, symbol: "ALAB", name: "Astera Labs")

    expect(search("alab").first[:change]).to be_nil
  end

  it "answers nothing for a query too short to mean anything" do
    create(:asset, :stock, symbol: "A", name: "Agilent")

    expect(search(" a ")).to eq([])
    expect(search(nil)).to eq([])
  end

  # Negative: LIKE wildcards in the query are text, not patterns.
  it "does not read a percent sign as match-everything" do
    create(:asset, :stock, symbol: "MSFT", name: "Microsoft")

    expect(search("%%")).to eq([])
  end

  it "returns at most eight results" do
    9.times { |i| create(:asset, :stock, symbol: "AB#{i}", name: "Ab #{i}") }

    expect(search("ab").size).to eq(8)
  end
end
