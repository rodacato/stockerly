require "rails_helper"

RSpec.describe SystemLog, type: :model do
  subject(:log) { build(:system_log) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires task_name" do
      log.task_name = nil
      expect(log).not_to be_valid
    end

    it "requires module_name" do
      log.module_name = nil
      expect(log).not_to be_valid
    end
  end

  describe "enums" do
    it "defines severity enum" do
      expect(SystemLog.severities).to eq("success" => 0, "error" => 1, "warning" => 2)
    end
  end

  describe "scopes" do
    before do
      create(:system_log, severity: :success, module_name: "Finance", created_at: 1.hour.ago)
      create(:system_log, :error, module_name: "Auth", created_at: 2.days.ago)
      create(:system_log, :warning, module_name: "Finance", created_at: 12.hours.ago)
    end

    it ".recent orders by created_at desc" do
      expect(SystemLog.recent.first.created_at).to be > SystemLog.recent.last.created_at
    end

    it ".errors returns only error logs" do
      expect(SystemLog.errors.count).to eq(1)
      expect(SystemLog.errors.first.severity).to eq("error")
    end

    it ".last_24h returns logs from last 24 hours" do
      expect(SystemLog.last_24h.count).to eq(2)
    end

    it ".by_module filters by module name" do
      expect(SystemLog.by_module("Finance").count).to eq(2)
    end

    it ".by_module returns all when module is nil" do
      expect(SystemLog.by_module(nil).count).to eq(3)
    end
  end
end
