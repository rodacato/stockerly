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

    # The defect this exists to prevent: a worktree under .claude/worktrees/
    # named its databases after its own directory alone, so nothing tied
    # `vix_index_symbols_test` back to this repository and WorktreeDatabases --
    # which only looks at prefixes belonging to this checkout -- could not see
    # it to prune it. 92 orphans accumulated before anyone counted.
    context "when the path is a git worktree" do
      let(:root) { Dir.mktmpdir }
      let(:worktree) { File.join(root, ".claude", "worktrees", "vix-index-symbols") }

      before do
        FileUtils.mkdir_p(worktree)
        File.write(File.join(worktree, ".git"), "gitdir: /workspaces/stockerly/.git/worktrees/vix-index-symbols\n")
      end

      after { FileUtils.remove_entry(root) }

      it "carries the main checkout's name, so the database says where it came from" do
        expect(described_class.prefix_for(worktree)).to eq("stockerly__vix_index_symbols")
      end

      it "stays inside the prefix WorktreeDatabases is allowed to look at" do
        expect(described_class.prefix_for(worktree)).to start_with(described_class.prefix_for("/workspaces/stockerly"))
      end

      it "leaves a main checkout alone, whose .git is a directory rather than a pointer" do
        main = File.join(root, "stockerly")
        FileUtils.mkdir_p(File.join(main, ".git"))

        expect(described_class.prefix_for(main)).to eq("stockerly")
      end
    end

    it "keeps the longest database name Postgres will accept" do
      long = "a" * 80
      allow(File).to receive(:file?).and_call_original
      allow(File).to receive(:file?).with(File.join("/tmp", long, ".git")).and_return(true)
      allow(File).to receive(:read).with(File.join("/tmp", long, ".git"))
        .and_return("gitdir: /workspaces/stockerly/.git/worktrees/#{long}")

      expect("#{described_class.prefix_for("/tmp/#{long}")}_development_cache".length).to be <= 63
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
