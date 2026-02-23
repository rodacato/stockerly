require "rails_helper"

RSpec.describe CreateAuditLogOnAssetCreation do
  let(:admin) { create(:user, :admin) }
  let(:asset) { create(:asset, symbol: "NVDA") }

  it "creates an audit log entry" do
    event = AssetCreated.new(asset_id: asset.id, symbol: asset.symbol, admin_id: admin.id)

    expect {
      described_class.call(event)
    }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("asset_created")
    expect(log.auditable).to eq(asset)
    expect(log.changes_data["after"]["symbol"]).to eq("NVDA")
  end

  it "does nothing when asset not found" do
    event = AssetCreated.new(asset_id: -1, symbol: "GONE", admin_id: admin.id)

    expect {
      described_class.call(event)
    }.not_to change(AuditLog, :count)
  end
end
