require "rails_helper"

RSpec.describe DataSourceRegistry do
  let(:test_gateway) { Class.new }
  let(:test_job) { Class.new }

  let(:attrs) do
    {
      icon: "sync",
      color: "blue",
      gateway_class: test_gateway,
      job_class: test_job,
      job_args: [ "foo" ],
      test_symbol: "TEST",
      test_method: :fetch_price,
      integration_name: "Test Provider",
      circuit_breaker_key: "test",
      capabilities: %i[prices historical]
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
      expect(source.gateway_class).to eq(test_gateway)
    end
  end

  # The label is not stored on the source: it is copy, so it comes from the
  # locale by key (#302). Asserted against a real registration, because a made
  # up key has no translation and would only prove the lookup raises.
  describe "#name" do
    it "reads the es-MX label the locale holds for its key" do
      described_class.clear!
      load Rails.root.join("config/initializers/data_sources.rb")

      expect(described_class.find(:banxico_cetes).name).to eq("CETES — Banxico")
    end
  end

  describe ".find with unknown key" do
    it "raises KeyError" do
      expect { described_class.find(:nonexistent) }.to raise_error(KeyError, /Unknown data source/)
    end
  end

  describe ".all" do
    it "returns all registered sources" do
      described_class.register(:source_a, **attrs)
      described_class.register(:source_b, **attrs)

      expect(described_class.all.map(&:key)).to contain_exactly(:source_a, :source_b)
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

    it "answers with the source that claims the integration" do
      described_class.register(:first, **attrs)
      described_class.register(:second, **attrs.merge(health_check: true))

      expect(described_class.for_integration("Test Provider").key).to eq(:second)
    end

    it "refuses to pick by registration order when several sources match" do
      described_class.register(:first, **attrs)
      described_class.register(:second, **attrs)

      expect { described_class.for_integration("Test Provider") }
        .to raise_error(DataSourceRegistry::AmbiguousHealthCheck, /2 sources/)
    end
  end

  # These run against the real registry rather than the fixtures above: the
  # defect they catch is a source declaring a probe its gateway cannot answer.
  describe "the registered sources" do
    before { load Rails.root.join("config/initializers/data_sources.rb") }

    it "name a probe method their gateway actually implements" do
      broken = described_class.all.reject { |s| s.gateway_class.instance_methods.include?(s.test_method) }

      expect(broken.map { |s| "#{s.key}##{s.test_method}" }).to be_empty
    end

    it "pass their probe enough arguments to call it" do
      underfed = described_class.all.reject do |s|
        required = s.gateway_class.instance_method(s.test_method).parameters.count { |type, _| type == :req }
        required <= [ s.test_symbol ].compact.size
      end

      expect(underfed.map(&:key)).to be_empty
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
      described_class.register(:source_b, **attrs)

      expect(described_class.keys).to contain_exactly(:source_a, :source_b)
    end
  end

  describe ".for_capability" do
    it "returns sources that have the requested capability" do
      described_class.register(:source_a, **attrs.merge(capabilities: %i[prices news]))
      described_class.register(:source_b, **attrs.merge(capabilities: %i[news earnings]))
      described_class.register(:source_c, **attrs.merge(capabilities: %i[earnings]))

      result = described_class.for_capability(:news)
      expect(result.map(&:key)).to eq([ :source_a, :source_b ])
    end

    it "returns empty array when no sources have the capability" do
      described_class.register(:source_a, **attrs.merge(capabilities: %i[prices]))

      expect(described_class.for_capability(:news)).to eq([])
    end

    it "preserves registration order" do
      described_class.register(:first, **attrs.merge(capabilities: %i[prices]))
      described_class.register(:second, **attrs.merge(capabilities: %i[prices]))
      described_class.register(:third, **attrs.merge(capabilities: %i[prices]))

      result = described_class.for_capability(:prices)
      expect(result.map(&:key)).to eq([ :first, :second, :third ])
    end
  end

  describe "routing by market and asset type" do
    let(:base) do
      attrs.except(:integration_name, :capabilities).merge(circuit_breaker_key: "scoped")
    end

    before do
      described_class.clear!
      described_class.register(:us_quotes, integration_name: "Finnhub", markets: %i[us],
                                           asset_types: %i[stock etf index], capabilities: %i[prices],
                                           **base)
      described_class.register(:crypto, integration_name: "CoinGecko", asset_types: %i[crypto],
                                        capabilities: %i[prices], **base)
      described_class.register(:bmv, integration_name: "DataBursatil", markets: %i[mx],
                                     asset_types: %i[stock etf index crypto], capabilities: %i[prices],
                                     **base)
      described_class.register(:bridge, integration_name: "Yahoo Finance",
                                        asset_types: %i[stock etf index], capabilities: %i[prices],
                                        **base)
    end

    def providers(market:, asset_type:)
      described_class.for_capability(:prices, market: market, asset_type: asset_type).map(&:integration_name)
    end

    it "keeps a Mexican equity on the Mexican source" do
      expect(providers(market: :mx, asset_type: :stock)).to eq(%w[DataBursatil Yahoo\ Finance])
    end

    it "keeps a US equity off the Mexican source" do
      expect(providers(market: :us, asset_type: :stock)).to eq(%w[Finnhub Yahoo\ Finance])
    end

    # Asset type outranks market: crypto is global, so a Mexican crypto leads
    # with the crypto source rather than with the exchange.
    it "sends a Mexican crypto to the crypto source first" do
      expect(providers(market: :mx, asset_type: :crypto)).to eq(%w[CoinGecko DataBursatil])
    end

    it "leaves the exchange out for a crypto that is not Mexican" do
      expect(providers(market: :us, asset_type: :crypto)).to eq(%w[CoinGecko])
    end

    it "serves anything when a source declares no scope" do
      described_class.register(:anything, integration_name: "Wildcard", capabilities: %i[prices], **base)

      expect(providers(market: :mx, asset_type: :crypto)).to include("Wildcard")
    end

    it "answers with nothing rather than guessing for a type nobody claims" do
      expect(providers(market: :us, asset_type: :fixed_income)).to be_empty
    end
  end
end
