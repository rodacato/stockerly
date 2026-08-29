require "rails_helper"

RSpec.describe MarketData::UseCases::RequestFundamentalSync do
  it "enqueues for a stock that has never been synced" do
    asset = create(:asset, :stock, fundamentals_synced_at: nil)

    expect { expect(described_class.call(asset: asset)).to be true }
      .to have_enqueued_job(SyncFundamentalJob).with(asset.id)
  end

  it "enqueues again once the cooldown has passed" do
    asset = create(:asset, :stock, fundamentals_synced_at: (described_class::COOLDOWN + 1.minute).ago)

    expect { expect(described_class.call(asset: asset)).to be true }
      .to have_enqueued_job(SyncFundamentalJob)
  end

  it "refuses inside the cooldown and says so" do
    asset = create(:asset, :stock, fundamentals_synced_at: 1.minute.ago)

    expect { expect(described_class.call(asset: asset)).to be false }
      .not_to have_enqueued_job(SyncFundamentalJob)
  end

  it "refuses for an asset type no provider covers" do
    crypto = create(:asset, :crypto)

    expect { expect(described_class.call(asset: crypto)).to be false }
      .not_to have_enqueued_job(SyncFundamentalJob)
  end
end
