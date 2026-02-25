require "rails_helper"

RSpec.describe AdaptiveScheduling do
  let(:job_class) do
    Class.new(ApplicationJob) do
      include AdaptiveScheduling

      def perform(action, key)
        case action
        when "backoff" then adaptive_backoff(key)
        when "reset" then adaptive_reset(key)
        when "read" then adaptive_multiplier(key)
        end
      end
    end
  end

  let(:job) { job_class.new }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  describe "#adaptive_backoff" do
    it "starts at 2x multiplier on first backoff" do
      result = job.perform("backoff", "polygon")
      expect(result).to eq(2)
    end

    it "doubles the multiplier on consecutive backoffs" do
      job.perform("backoff", "polygon")
      result = job.perform("backoff", "polygon")
      expect(result).to eq(4)
    end

    it "caps at 4x multiplier" do
      3.times { job.perform("backoff", "polygon") }
      result = job.perform("backoff", "polygon")
      expect(result).to eq(4)
    end
  end

  describe "#adaptive_reset" do
    it "resets the multiplier to 1" do
      job.perform("backoff", "polygon")
      job.perform("reset", "polygon")
      result = job.perform("read", "polygon")
      expect(result).to eq(1)
    end
  end

  describe "#adaptive_multiplier" do
    it "returns 1 when no backoff has occurred" do
      result = job.perform("read", "polygon")
      expect(result).to eq(1)
    end

    it "returns current multiplier after backoff" do
      job.perform("backoff", "coingecko")
      result = job.perform("read", "coingecko")
      expect(result).to eq(2)
    end
  end
end
