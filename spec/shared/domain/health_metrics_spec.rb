require "rails_helper"

RSpec.describe HealthMetrics do
  describe ".queue_workers" do
    it "counts nothing while no worker has registered" do
      expect(described_class.queue_workers).to eq(0)
    end

    it "counts each registered worker" do
      register_queue_worker
      register_queue_worker

      expect(described_class.queue_workers).to eq(2)
    end
  end

  describe ".queue_attended?" do
    it "is false while no worker has registered" do
      expect(described_class.queue_attended?).to be false
    end

    it "is false when the queue cannot be read at all" do
      allow(SolidQueue::Record).to receive(:transaction).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect(described_class.queue_attended?).to be false
    end

    it "is true once a worker has registered" do
      register_queue_worker

      expect(described_class.queue_attended?).to be true
    end
  end
end
