require "rails_helper"

RSpec.describe Administration::Domain::ErrorFingerprint do
  describe ".digest" do
    it "gives the same digest to the same class and line" do
      first = described_class.digest("ArgumentError", "app/models/thing.rb:12")
      second = described_class.digest("ArgumentError", "app/models/thing.rb:12")

      expect(first).to eq(second)
    end

    it "separates the same class raised from a different line" do
      first = described_class.digest("ArgumentError", "app/models/thing.rb:12")
      second = described_class.digest("ArgumentError", "app/models/thing.rb:40")

      expect(first).not_to eq(second)
    end

    it "separates different classes raised from the same line" do
      first = described_class.digest("ArgumentError", "app/models/thing.rb:12")
      second = described_class.digest("TypeError", "app/models/thing.rb:12")

      expect(first).not_to eq(second)
    end
  end

  describe ".clean" do
    it "leads with the application frame, not the gem frame above it" do
      backtrace = [
        "#{Gem.dir}/gems/activerecord-8.1.3.1/lib/active_record/relation.rb:10:in `find'",
        "#{Rails.root}/app/models/thing.rb:12:in `call'"
      ]

      expect(described_class.clean(backtrace).first).to include("app/models/thing.rb:12")
    end

    it "keeps the raw frames when nothing is application code" do
      backtrace = [ "#{Gem.dir}/gems/rack/lib/rack.rb:1:in `call'" ]

      expect(described_class.clean(backtrace)).to eq(backtrace)
    end

    it "returns nothing to lead with for an error carrying no backtrace" do
      expect(described_class.clean(nil)).to be_empty
    end

    it "caps the stored frames" do
      backtrace = Array.new(100) { |i| "#{Rails.root}/app/models/thing.rb:#{i}:in `call'" }

      expect(described_class.clean(backtrace).length).to eq(described_class::BACKTRACE_LIMIT)
    end
  end
end
