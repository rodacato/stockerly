require "rails_helper"

RSpec.describe Administration::UseCases::Dashboard::LoadHealthMetrics do
  describe ".call" do
    it "returns Success with all health metric keys" do
      result = described_class.call

      expect(result).to be_success
      health = result.value!
      expect(health).to have_key(:queue_depth)
      expect(health).to have_key(:in_progress_jobs)
      expect(health).to have_key(:failed_jobs)
      expect(health).to have_key(:scheduled_jobs)
      expect(health).to have_key(:queue_workers)
      expect(health).to have_key(:cache_entries)
      expect(health).to have_key(:cache_byte_size)
      expect(health).to have_key(:circuit_breaker_events)
      expect(health).to have_key(:open_circuits_count)
    end

    it "returns circuit breaker events from SystemLog" do
      create(:system_log,
        module_name: "resilience",
        task_name: "Circuit Breaker: stock",
        severity: :warning,
        error_message: "Transitioned from closed to open")

      result = described_class.call
      events = result.value![:circuit_breaker_events]

      expect(events.count).to eq(1)
      expect(events.first.task_name).to eq("Circuit Breaker: stock")
    end

    it "counts distinct open circuits in last 24 hours" do
      create(:system_log,
        module_name: "resilience",
        task_name: "Circuit Breaker: stock",
        severity: :warning,
        error_message: "Transitioned from closed to open")
      create(:system_log,
        module_name: "resilience",
        task_name: "Circuit Breaker: yahoo",
        severity: :warning,
        error_message: "Transitioned from closed to open")
      create(:system_log,
        module_name: "resilience",
        task_name: "Circuit Breaker: stock",
        severity: :success,
        error_message: "Transitioned from half_open to closed")

      result = described_class.call

      expect(result.value![:open_circuits_count]).to eq(2)
    end

    it "handles unavailable queue and cache tables gracefully" do
      result = described_class.call
      health = result.value!

      expect(health[:circuit_breaker_events]).to respond_to(:count)
      expect(health[:open_circuits_count]).to eq(0)
    end
  end
end
