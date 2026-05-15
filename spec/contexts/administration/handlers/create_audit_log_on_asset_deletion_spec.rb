require "rails_helper"

RSpec.describe Administration::Handlers::CreateAuditLogOnAssetDeletion do
  let(:admin) { create(:user, :admin) }

  it "creates an audit log entry capturing the deleted symbol" do
    event = MarketData::Events::AssetDeleted.new(asset_symbol: "TSLA", admin_id: admin.id)

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(admin.id)
    expect(log.action).to eq("asset_deleted")
    expect(log.changes_data["asset_symbol"]).to eq("TSLA")
    expect(log.auditable).to be_nil # the asset row is gone by handle time
  end
end
