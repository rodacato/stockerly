require "rails_helper"

RSpec.describe SyncLogging do
  let(:job_class) do
    Class.new(ApplicationJob) do
      include SyncLogging
      def perform_success = log_sync_success("Test Task")
      def perform_failure = log_sync_failure("Test Task", "Something went wrong")
      def perform_warning = log_sync_failure("Test Task", "Rate limited", severity: :warning)
    end
  end

  let(:job) { job_class.new }

  describe "#log_sync_success" do
    it "creates a success SystemLog entry" do
      expect { job.perform_success }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Test Task")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
    end
  end

  describe "#log_sync_failure" do
    it "creates an error SystemLog entry with message" do
      expect { job.perform_failure }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.severity).to eq("error")
      expect(log.error_message).to eq("Something went wrong")
    end

    it "supports custom severity for warnings" do
      job.perform_warning

      log = SystemLog.last
      expect(log.severity).to eq("warning")
      expect(log.error_message).to eq("Rate limited")
    end
  end
end
