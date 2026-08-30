require "rails_helper"

RSpec.describe Trading::UseCases::RebuildSnapshots do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) do
    (user.portfolio || create(:portfolio, user: user))
      .tap { |p| p.update!(inception_date: 30.days.ago.to_date) }
  end
  let(:asset) { create(:asset, :stock, symbol: "WALMEX", currency: "MXN", current_price: 70) }

  def buy(shares, price, on:)
    create(:trade, portfolio: portfolio, asset: asset, side: :buy, shares: shares,
                   price_per_share: price, currency: "MXN", executed_at: on)
  end

  def close(price, on:)
    create(:asset_price_history, asset: asset, date: on, close: price)
  end

  # The exact reproduction from D27.
  it "corrects a snapshot that predates a backdated trade" do
    portfolio.snapshots.create!(date: 5.days.ago.to_date, currency: "MXN",
                                total_value: 0)
    buy(100, 10, on: 5.days.ago)
    close(10, on: 5.days.ago.to_date)

    described_class.call(portfolio: portfolio, from: 5.days.ago.to_date)

    snapshot = portfolio.snapshots.find_by(date: 5.days.ago.to_date)
    expect(snapshot.total_value).to eq(1_000)
    expect(snapshot.total_value).to eq(1_000)
  end

  it "writes a snapshot for every date in the range" do
    buy(100, 10, on: 4.days.ago)
    close(10, on: 4.days.ago.to_date)

    written = described_class.call(portfolio: portfolio, from: 4.days.ago.to_date)

    expect(written).to eq(5)
    expect(portfolio.snapshots.pluck(:date)).to match_array((4.days.ago.to_date..Date.current).to_a)
  end

  it "is idempotent — a second run changes nothing" do
    buy(100, 10, on: 3.days.ago)
    close(10, on: 3.days.ago.to_date)

    described_class.call(portfolio: portfolio, from: 3.days.ago.to_date)
    first = portfolio.snapshots.order(:date).pluck(:date, :total_value)
    described_class.call(portfolio: portfolio, from: 3.days.ago.to_date)

    expect(portfolio.snapshots.order(:date).pluck(:date, :total_value)).to eq(first)
  end

  it "never writes before the portfolio existed" do
    portfolio.update!(inception_date: 2.days.ago.to_date)
    buy(100, 10, on: 2.days.ago)
    close(10, on: 2.days.ago.to_date)

    described_class.call(portfolio: portfolio, from: 60.days.ago.to_date)

    expect(portfolio.snapshots.minimum(:date)).to eq(2.days.ago.to_date)
  end

  it "never writes a snapshot in the future" do
    buy(100, 10, on: 1.day.ago)
    close(10, on: 1.day.ago.to_date)

    described_class.call(portfolio: portfolio, from: 1.day.ago.to_date, to: 10.days.from_now.to_date)

    expect(portfolio.snapshots.maximum(:date)).to eq(Date.current)
  end

  it "does nothing when the range is empty" do
    expect(described_class.call(portfolio: portfolio, from: 5.days.from_now.to_date)).to eq(0)
    expect(portfolio.snapshots).to be_empty
  end
end
