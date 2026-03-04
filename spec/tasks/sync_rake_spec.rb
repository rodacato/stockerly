require "rails_helper"
require "rake"

RSpec.describe "stockerly:sync rake task" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("stockerly:sync")
  end

  before do
    Rake::Task["stockerly:sync"].reenable
  end

  describe "integration sync" do
    it "creates missing Integration records from DataSourceRegistry" do
      expect {
        Rake::Task["stockerly:sync"].invoke
      }.to change(Integration, :count)

      provider_names = DataSourceRegistry.all.map(&:integration_name).uniq
      provider_names.each do |name|
        expect(Integration.exists?(provider_name: name)).to be(true), "Expected Integration for #{name}"
      end
    end

    it "is idempotent — running twice does not duplicate records" do
      Rake::Task["stockerly:sync"].invoke
      count_after_first = Integration.count

      Rake::Task["stockerly:sync"].reenable
      Rake::Task["stockerly:sync"].invoke

      expect(Integration.count).to eq(count_after_first)
    end

    it "does not overwrite existing Integration attributes" do
      create(:integration, provider_name: "Polygon.io", provider_type: "Custom Type",
             daily_call_limit: 999, max_requests_per_minute: 99)

      Rake::Task["stockerly:sync"].invoke

      polygon = Integration.find_by(provider_name: "Polygon.io")
      expect(polygon.provider_type).to eq("Custom Type")
      expect(polygon.daily_call_limit).to eq(999)
      expect(polygon.max_requests_per_minute).to eq(99)
    end

    it "applies correct defaults for known providers" do
      Rake::Task["stockerly:sync"].invoke

      finnhub = Integration.find_by(provider_name: "Finnhub")
      expect(finnhub.provider_type).to eq("Stocks & Market Data")
      expect(finnhub.requires_api_key).to be(true)
      expect(finnhub.max_requests_per_minute).to eq(60)
      expect(finnhub.daily_call_limit).to eq(500)
      expect(finnhub.connection_status).to eq("disconnected")
    end

    it "applies fallback defaults for unknown providers" do
      DataSourceRegistry.register(:test_source,
        name: "Test", icon: "test", color: "gray",
        gateway_class: MarketData::Gateways::MarketDataGateway,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "NewProvider", circuit_breaker_key: "test"
      )

      Rake::Task["stockerly:sync"].invoke

      provider = Integration.find_by(provider_name: "NewProvider")
      expect(provider).to be_present
      expect(provider.provider_type).to eq("External API")
      expect(provider.requires_api_key).to be(true)
      expect(provider.daily_call_limit).to eq(500)
    end
  end
end
