require "rails_helper"
require "rake"

RSpec.describe "stockerly:reset_trades rake task" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("stockerly:reset_trades")
  end

  before { Rake::Task["stockerly:reset_trades"].reenable }

  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user, inception_date: Date.new(2025, 11, 11)) }
  let(:asset) { create(:asset, :stock, symbol: "VT") }

  def stock_the_portfolio
    position = create(:position, portfolio: portfolio, asset: asset)
    create(:trade, portfolio: portfolio, asset: asset, position: position)
    create(:portfolio_snapshot, portfolio: portfolio)
    portfolio
  end

  it "deletes nothing without COMMIT" do
    stock_the_portfolio

    expect { Rake::Task["stockerly:reset_trades"].invoke }.to output(/DRY RUN/).to_stdout

    expect(portfolio.trades.count).to eq(1)
    expect(portfolio.positions.count).to eq(1)
    expect(portfolio.snapshots.count).to eq(1)
    expect(portfolio.reload.inception_date).to eq(Date.new(2025, 11, 11))
  end

  context "with COMMIT=1" do
    around do |example|
      previous = ENV["COMMIT"]
      ENV["COMMIT"] = "1"
      example.run
    ensure
      ENV["COMMIT"] = previous
    end

    it "removes the trades, positions and snapshots" do
      stock_the_portfolio

      expect { Rake::Task["stockerly:reset_trades"].invoke }.to output(/Deleting/).to_stdout

      expect(portfolio.trades.count).to eq(0)
      expect(portfolio.positions.count).to eq(0)
      expect(portfolio.snapshots.count).to eq(0)
    end

    it "clears inception_date so the next import backdates it to its own earliest trade" do
      stock_the_portfolio

      expect { Rake::Task["stockerly:reset_trades"].invoke }
        .to change { portfolio.reload.inception_date }.to(nil)
    end

    # The expensive half of the database: re-fetching any of it costs provider
    # calls, and none of it is derived from a trade.
    it "leaves the catalogue, the FX history and the account itself alone" do
      stock_the_portfolio
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 11, 11), rate: 20.1, source: "banxico")

      Rake::Task["stockerly:reset_trades"].invoke

      expect(Asset.where(symbol: "VT")).to exist
      expect(FxRateHistory.count).to eq(1)
      expect(User.count).to eq(1)
      expect(Portfolio.count).to eq(1)
    end
  end
end
