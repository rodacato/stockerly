require "rails_helper"
require Rails.root.join("script/release_changelog")

RSpec.describe ReleaseChangelog do
  describe ".bump" do
    it "drops the pre-release suffix on a patch instead of counting past it" do
      expect(described_class.bump("0.1.0-rc1", "patch")).to eq("0.1.0")
    end

    it "counts the patch when there is no suffix to drop" do
      expect(described_class.bump("0.2.1", "patch")).to eq("0.2.2")
    end

    it "zeroes the components below the one it raises" do
      expect(described_class.bump("0.1.0-rc1", "minor")).to eq("0.2.0")
      expect(described_class.bump("0.2.7", "major")).to eq("1.0.0")
    end

    it "refuses a bump it does not know" do
      expect { described_class.bump("0.2.0", "release") }.to raise_error(ArgumentError)
    end
  end

  describe ".parse_subject" do
    it "reads the scope and marks the bang as breaking" do
      expect(described_class.parse_subject("feat(trading)!: capture FX at execution")).to include(
        type: "feat", scope: "trading", description: "capture FX at execution", breaking: true
      )
    end

    it "leaves a subject without a prefix unparsed" do
      expect(described_class.parse_subject("Leave a flat index change uncoloured")).to be_nil
    end

    it "does not read a colon that arrives mid-sentence as a type" do
      expect(described_class.parse_subject("Report the Banxico failure: on the key step")).to be_nil
    end
  end

  describe ".group" do
    subject(:grouped) { described_class.group(commits) }

    let(:commits) do
      [
        { sha: "a" * 40, subject: "feat(alerts): evaluate volume spikes" },
        { sha: "b" * 40, subject: "fix!: stop double-counting a closed position" },
        { sha: "c" * 40, subject: "Re-export the artboards accent text moved under" },
        { sha: "d" * 40, subject: "design(cockpit): draw the empty radar" }
      ]
    end

    it "collects only the bang as breaking" do
      expect(grouped[:breaking].pluck(:description)).to eq([ "stop double-counting a closed position" ])
    end

    it "reports a subject with no prefix rather than losing it" do
      expect(grouped[:dropped]).to include(hash_including(sha: "c" * 40, why: "not a conventional commit"))
    end

    it "says why a silenced type is absent" do
      expect(grouped[:dropped]).to include(hash_including(sha: "d" * 40, why: /Log frame/))
    end

    it "keeps every commit either grouped or reported" do
      placed = grouped[:groups].values.flatten + grouped[:dropped]

      expect(placed.size).to eq(commits.size)
    end
  end

  describe ".format_entry" do
    subject(:entry) { described_class.format_entry("0.3.0", "2026-09-22", grouped, carried: carried) }

    let(:grouped) { described_class.group(commits) }
    let(:carried) { "" }
    let(:commits) do
      [
        { sha: "a" * 40, subject: "feat(alerts): evaluate volume spikes" },
        { sha: "b" * 40, subject: "refactor(trading): extract the FX resolver" },
        { sha: "c" * 40, subject: "perf: memoise the holdings query" }
      ]
    end

    it "prints one Changed heading for the types that read as Changed" do
      expect(entry.scan(/^### Changed$/).size).to eq(1)
    end

    it "prefixes the scope and leaves a scopeless bullet bare" do
      expect(entry).to include("- **alerts:** evaluate volume spikes")
      expect(entry).to include("- memoise the holdings query")
    end

    context "when [Unreleased] was written by hand" do
      let(:carried) { "### The 2.0 pivot\n\nWhat changed and why." }

      it "carries that prose into the entry above the generated sections" do
        expect(entry.index("The 2.0 pivot")).to be < entry.index("### Added")
      end
    end
  end

  describe "writing the files" do
    subject(:release) { described_class.main([ "minor" ], root: repo) }

    let(:repo) { Dir.mktmpdir("release-changelog") }
    let(:version_path) { File.join(repo, "lib/stockerly/version.rb") }
    let(:changelog_path) { File.join(repo, "CHANGELOG.md") }

    before { seed_repository }

    after { FileUtils.remove_entry(repo) }

    def git(*args)
      out, status = Open3.capture2("git", "-C", repo, *args)
      raise "git #{args.join(' ')} failed: #{out}" unless status.success?
    end

    def seed_repository
      seed_files
      seed_history
    end

    def seed_files
      FileUtils.mkdir_p(File.dirname(version_path))
      File.write(version_path, %(module Stockerly\n  VERSION = "0.1.0"\nend\n))
      File.write(changelog_path, <<~MARKDOWN)
        # Changelog

        ## [Unreleased]

        ## [0.1.0] - 2026-01-01

        ### Added

        - The first thing.

        [Unreleased]: https://github.com/rodacato/stockerly/compare/v0.1.0...HEAD
        [0.1.0]: https://github.com/rodacato/stockerly/releases/tag/v0.1.0
      MARKDOWN
    end

    def seed_history
      git("init", "--initial-branch", "master")
      git("config", "user.email", "test@example.com")
      git("config", "user.name", "Test")
      git("add", ".")
      git("commit", "-m", "chore: seed the repository")
      git("tag", "-a", "v0.1.0", "-m", "Release v0.1.0")
      git("commit", "--allow-empty", "-m", "feat(trading): record the trade's FX rate")
      git("commit", "--allow-empty", "-m", "Rename the thing without a prefix")
      git("commit", "--allow-empty", "-m", "chore: bump a dependency")
    end

    def changelog = File.read(changelog_path)

    def manifest = File.read(version_path)

    it "writes the bumped version to the manifest" do
      release

      expect(manifest).to include(%(VERSION = "0.2.0"))
    end

    it "reads only the commits after the last tag" do
      release

      expect(changelog).to include("- **trading:** record the trade's FX rate")
      expect(changelog).not_to include("seed the repository")
    end

    it "leaves an empty [Unreleased] above the new entry" do
      release

      expect(changelog).to match(/## \[Unreleased\]\n\n## \[0\.2\.0\] - \d{4}-\d{2}-\d{2}/)
    end

    it "keeps the older entry and its link definition" do
      release

      expect(changelog).to include("## [0.1.0] - 2026-01-01")
      expect(changelog).to include("[0.1.0]: https://github.com/rodacato/stockerly/releases/tag/v0.1.0")
    end

    it "points the new links at the tag the range started from" do
      release

      expect(changelog).to include("[Unreleased]: https://github.com/rodacato/stockerly/compare/v0.2.0...HEAD")
      expect(changelog).to include("[0.2.0]: https://github.com/rodacato/stockerly/compare/v0.1.0...v0.2.0")
    end

    it "writes nothing on a dry run" do
      described_class.main([ "minor", "--dry-run" ], root: repo)

      expect(manifest).to include(%(VERSION = "0.1.0"))
      expect(changelog).to include("## [Unreleased]\n\n## [0.1.0]")
    end

    it "reports the prefixless commit on stderr instead of publishing a silent gap" do
      expect { described_class.main([ "minor", "--dry-run" ], root: repo) }
        .to output(/Rename the thing without a prefix  — not a conventional commit/).to_stderr
    end
  end
end
