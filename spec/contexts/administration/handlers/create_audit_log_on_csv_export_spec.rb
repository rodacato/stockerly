require "rails_helper"

RSpec.describe Administration::Handlers::CreateAuditLogOnCsvExport do
  let(:user) { create(:user, :admin) }

  it "creates an audit log entry with the export_type" do
    event = Administration::Events::CsvExported.new(user_id: user.id, export_type: "trades")

    expect { described_class.call(event) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.action).to eq("csv_exported")
    expect(log.changes_data["export_type"]).to eq("trades")
  end
end
