require "rails_helper"

RSpec.describe Administration::Handlers::CreateAuditLogOnAssetUpdate do
  let(:admin) { create(:user, :admin) }
  let(:asset) { create(:asset, symbol: "AAPL") }
  let(:changes) { { "name" => { from: "Apple", to: "Apple Inc." } } }

  it "creates an audit log entry with the change diff" do
    event = Administration::Events::AssetUpdated.new(asset_id: asset.id, admin_id: admin.id, symbol: asset.symbol, changes: changes)

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("asset_updated")
    expect(log.auditable).to eq(asset)
    expect(log.changes_data["symbol"]).to eq("AAPL")
    expect(log.changes_data["changes"]).to be_present
  end

  it "still creates the audit row with nil auditable when asset is gone between publish and handle" do
    event = Administration::Events::AssetUpdated.new(asset_id: -1, admin_id: admin.id, symbol: "GONE", changes: { "name" => { from: "Was", to: "Now" } })

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("asset_updated")
    expect(log.auditable).to be_nil
    expect(log.changes_data["symbol"]).to eq("GONE")
    expect(log.changes_data["changes"]).to be_present
  end
end
