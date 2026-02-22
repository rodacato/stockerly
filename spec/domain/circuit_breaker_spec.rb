require "rails_helper"

RSpec.describe CircuitBreaker do
  include Dry::Monads[:result]
  include ActiveSupport::Testing::TimeHelpers

  subject(:breaker) { described_class.new(name: "test", threshold: 3, timeout: 2) }

  let(:success_result) { Success({ price: 150.0 }) }
  let(:failure_result) { Failure([:gateway_error, "Server error"]) }

  describe "initial state" do
    it "starts closed" do
      expect(breaker.state).to eq(:closed)
      expect(breaker.failure_count).to eq(0)
    end
  end

  describe "closed state" do
    it "passes through success results" do
      result = breaker.call { success_result }

      expect(result).to be_success
      expect(breaker.state).to eq(:closed)
    end

    it "increments failure count on failure" do
      breaker.call { failure_result }

      expect(breaker.failure_count).to eq(1)
      expect(breaker.state).to eq(:closed)
    end

    it "transitions to open after reaching threshold" do
      3.times { breaker.call { failure_result } }

      expect(breaker.state).to eq(:open)
    end

    it "handles exceptions as failures" do
      result = breaker.call { raise Faraday::TimeoutError, "timeout" }

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:gateway_error)
      expect(breaker.failure_count).to eq(1)
    end
  end

  describe "open state" do
    before do
      3.times { breaker.call { failure_result } }
    end

    it "returns circuit_open failure without calling block" do
      block_called = false
      result = breaker.call { block_called = true; success_result }

      expect(block_called).to be false
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:circuit_open)
    end

    it "transitions to half_open after timeout" do
      travel_to 3.seconds.from_now do
        breaker.call { success_result }

        expect(breaker.state).to eq(:closed)
      end
    end
  end

  describe "half_open state" do
    before do
      3.times { breaker.call { failure_result } }
      travel_to 3.seconds.from_now
      # This call transitions to half_open, then succeeds → closed
    end

    it "transitions to closed on success" do
      breaker.call { success_result }

      expect(breaker.state).to eq(:closed)
    end

    it "transitions back to open on failure" do
      # First call after timeout: transitions to half_open, then fails
      breaker.call { failure_result }

      # The failure count is now 4 (3 + 1), which exceeds threshold → open
      expect(breaker.state).to eq(:open)
    end
  end

  describe "#reset!" do
    it "resets to closed state" do
      3.times { breaker.call { failure_result } }
      expect(breaker.state).to eq(:open)

      breaker.reset!

      expect(breaker.state).to eq(:closed)
      expect(breaker.failure_count).to eq(0)
    end
  end

  describe "logging" do
    it "creates a SystemLog on transition to open" do
      expect {
        3.times { breaker.call { failure_result } }
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Circuit Breaker: test")
      expect(log.severity).to eq("warning")
    end

    it "creates a SystemLog on transition to closed" do
      3.times { breaker.call { failure_result } }

      travel_to 3.seconds.from_now do
        # Logs twice: open→half_open (transition_to in call) + half_open→closed (on success)
        expect {
          breaker.call { success_result }
        }.to change(SystemLog, :count).by(2)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.error_message).to include("closed")
      end
    end
  end
end
