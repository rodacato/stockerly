require "rails_helper"

RSpec.describe Stockerly::Checkout do
  describe ".prefix_for" do
    it "names the group after the checkout directory" do
      expect(described_class.prefix_for("/workspaces/stockerly")).to eq("stockerly")
    end

    it "replaces the characters Postgres will not take in an identifier" do
      expect(described_class.prefix_for("/workspaces/stockerly-486")).to eq("stockerly_486")
      expect(described_class.prefix_for("/workspaces/fix.the thing")).to eq("fix_the_thing")
    end

    it "gives two worktrees of one repository two different prefixes" do
      main = described_class.prefix_for("/workspaces/stockerly")
      worktree = described_class.prefix_for("/workspaces/stockerly-486")

      expect(main).not_to eq(worktree)
    end
  end

  describe ".database_prefix" do
    it "derives the prefix from the checkout this code was loaded from" do
      expect(described_class.database_prefix).to eq(described_class.prefix_for(Rails.root))
    end

    it "lets the environment override the derived name" do
      original = ENV["DATABASE_PREFIX"]
      ENV["DATABASE_PREFIX"] = "explicit_name"

      expect(described_class.database_prefix).to eq("explicit_name")
    ensure
      ENV["DATABASE_PREFIX"] = original
    end
  end

  describe "the configured databases" do
    it "names every development and test database after this checkout" do
      configured = Rails.application.config.database_configuration
        .values_at("development", "test")
        .flat_map { |env| env.values.map { |role| role["database"] } }

      expect(configured).to all(start_with("#{described_class.database_prefix}_"))
    end

    it "leaves production alone, where there are no worktrees" do
      production = Rails.application.config.database_configuration["production"]

      expect(production["cache"]["database"]).to eq("stockerly_production_cache")
    end
  end
end
