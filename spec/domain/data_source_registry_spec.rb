require "rails_helper"

RSpec.describe DataSourceRegistry do
  let(:test_gateway) { Class.new }
  let(:test_job) { Class.new }

  let(:attrs) do
    {
      name: "Test Source",
      icon: "sync",
      color: "blue",
      gateway_class: test_gateway,
      job_class: test_job,
      job_args: [ "foo" ],
      test_symbol: "TEST",
      integration_name: "Test Provider",
      circuit_breaker_key: "test"
    }
  end

  around do |example|
    saved = described_class.instance_variable_get(:@sources).dup
    described_class.clear!
    example.run
    described_class.instance_variable_set(:@sources, saved)
  end

  describe ".register and .find" do
    it "registers and retrieves a data source by key" do
      described_class.register(:test_source, **attrs)
      source = described_class.find(:test_source)

      expect(source.key).to eq(:test_source)
      expect(source.name).to eq("Test Source")
      expect(source.gateway_class).to eq(test_gateway)
    end
  end

  describe ".find with unknown key" do
    it "raises KeyError" do
      expect { described_class.find(:nonexistent) }.to raise_error(KeyError, /Unknown data source/)
    end
  end

  describe ".all" do
    it "returns all registered sources" do
      described_class.register(:source_a, **attrs.merge(name: "A"))
      described_class.register(:source_b, **attrs.merge(name: "B"))

      expect(described_class.all.map(&:name)).to contain_exactly("A", "B")
    end
  end

  describe ".for_integration" do
    it "finds source matching integration provider_name" do
      described_class.register(:test_source, **attrs)

      source = described_class.for_integration("Test Provider")
      expect(source.key).to eq(:test_source)
    end

    it "returns nil when no match" do
      expect(described_class.for_integration("Unknown")).to be_nil
    end
  end

  describe ".clear!" do
    it "removes all registered sources" do
      described_class.register(:test_source, **attrs)
      described_class.clear!

      expect(described_class.all).to be_empty
    end
  end

  describe ".keys" do
    it "returns all registered keys" do
      described_class.register(:source_a, **attrs)
      described_class.register(:source_b, **attrs.merge(name: "B"))

      expect(described_class.keys).to contain_exactly(:source_a, :source_b)
    end
  end
end
