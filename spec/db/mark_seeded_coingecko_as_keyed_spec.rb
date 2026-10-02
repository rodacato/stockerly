require "rails_helper"
require Rails.root.join("db/migrate/20260917120000_mark_seeded_coingecko_as_keyed")

RSpec.describe MarkSeededCoingeckoAsKeyed do
  def migrate_up = ActiveRecord::Migration.suppress_messages { described_class.new.up }

  it "marks the seeded CoinGecko row as keyed" do
    create(:integration, :keyless, provider_name: "CoinGecko")

    migrate_up

    expect(Integration.find_by(provider_name: "CoinGecko").requires_api_key).to be(true)
  end

  it "is idempotent" do
    create(:integration, provider_name: "CoinGecko", requires_api_key: true)

    expect { migrate_up }.not_to(change { Integration.find_by(provider_name: "CoinGecko").requires_api_key })
  end

  it "leaves the other providers alone" do
    create(:integration, :keyless, provider_name: "Yahoo Finance")

    migrate_up

    expect(Integration.find_by(provider_name: "Yahoo Finance").requires_api_key).to be(false)
  end
end
