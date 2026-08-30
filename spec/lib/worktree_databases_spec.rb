require "rails_helper"

RSpec.describe WorktreeDatabases do
  let(:worktrees) { [ "/workspaces/stockerly", "/workspaces/stockerly-486" ] }
  let(:databases) do
    %w[
      postgres
      stockerly_development stockerly_development_cache stockerly_development_queue stockerly_development_cable
      stockerly_test stockerly_test_cache stockerly_test_queue stockerly_test_cable
      stockerly_486_development stockerly_486_test
      stockerly_501_development stockerly_501_test
    ]
  end

  describe ".groups" do
    subject(:groups) { described_class.groups(database_names: databases, worktree_paths: worktrees) }

    it "gathers the eight databases of a checkout under one prefix" do
      main = groups.find { |group| group.prefix == "stockerly" }

      expect(main.databases.size).to eq(8)
      expect(main.worktree).to eq("/workspaces/stockerly")
    end

    it "keeps a live worktree's databases separate from the main checkout's" do
      expect(groups.map(&:prefix)).to include("stockerly", "stockerly_486")
    end

    it "ignores databases that belong to no checkout of this repository" do
      expect(groups.flat_map(&:databases)).not_to include("postgres")
    end
  end

  describe ".orphans" do
    subject(:orphans) { described_class.orphans(database_names: databases, worktree_paths: worktrees) }

    it "reports the group whose worktree is gone" do
      expect(orphans.map(&:prefix)).to eq([ "stockerly_501" ])
    end

    it "never reports the main checkout" do
      expect(orphans.map(&:prefix)).not_to include("stockerly")
    end

    it "never reports a worktree that still exists" do
      expect(orphans.map(&:prefix)).not_to include("stockerly_486")
    end

    it "refuses to work when git reports no worktrees, rather than calling everything an orphan" do
      expect { described_class.orphans(database_names: databases, worktree_paths: []) }
        .to raise_error(described_class::Error, /refusing/)
    end

    it "leaves databases outside this repository's naming alone" do
      unrelated = databases + %w[some_other_app_development some_other_app_test]

      orphans = described_class.orphans(database_names: unrelated, worktree_paths: worktrees)

      expect(orphans.map(&:prefix)).not_to include("some_other_app")
    end
  end

  describe ".drop!" do
    self.use_transactional_tests = false

    let(:prefix) { "#{Stockerly::Checkout.database_prefix}_droppable" }
    let(:name) { "#{prefix}_development" }
    let(:connection) { ActiveRecord::Base.connection }

    before { connection.execute("CREATE DATABASE #{connection.quote_table_name(name)}") }
    after { connection.execute("DROP DATABASE IF EXISTS #{connection.quote_table_name(name)}") }

    it "drops every database in the group" do
      group = described_class.groups(worktree_paths: [ Rails.root.to_s ]).find { |g| g.prefix == prefix }

      expect { described_class.drop!(group) }
        .to change { described_class.existing_database_names.include?(name) }.from(true).to(false)
    end

    it "refuses to drop a group that still has a worktree" do
      live = described_class::Group.new(prefix: prefix, databases: [ name ], worktree: "/workspaces/somewhere")

      expect { described_class.drop!(live) }.to raise_error(described_class::Error, /still has a worktree/)
      expect(described_class.existing_database_names).to include(name)
    end
  end

  describe ".live_worktree_paths" do
    it "reads the worktrees git actually has, main checkout first" do
      paths = described_class.live_worktree_paths

      expect(paths).to include(Rails.root.to_s)
      expect(paths.first).not_to include("stockerly-486")
    end
  end
end
