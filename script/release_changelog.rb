#!/usr/bin/env ruby
# frozen_string_literal: true

# Bumps lib/stockerly/version.rb and writes that version's CHANGELOG entry from
# the conventional commits since the last v* tag. The Release workflow runs it;
# --dry-run prints the entry and writes nothing.
#
#   script/release_changelog.rb minor --dry-run
#
# A subject without a conventional prefix is not in the entry. It is reported on
# stderr instead of dropped in silence, which is what the release pull request
# is read against.

require "date"
require "open3"

module ReleaseChangelog
  ROOT       = File.expand_path("..", __dir__)
  REPO_URL   = "https://github.com/rodacato/stockerly"
  UNRELEASED = "## [Unreleased]"
  USAGE      = "usage: script/release_changelog.rb patch|minor|major [--dry-run]"
  BUMPS      = %w[patch minor major].freeze

  TYPE_LABELS = {
    "feat"     => "Added",
    "fix"      => "Fixed",
    "perf"     => "Changed",
    "refactor" => "Changed",
    "style"    => "Changed",
    "docs"     => "Documentation",
    "chore"    => "Maintenance",
    "test"     => "Testing",
    "ci"       => "CI"
  }.freeze

  # Left out on purpose, with its reason, because "absent from TYPE_LABELS" is
  # how a commit disappears without a word. A .pen file's history is its flow's
  # Log frame and design/DECISIONS.md.
  SILENT_TYPES = { "design" => "design/*.pen — its history is the flow's Log frame" }.freeze

  SUBJECT = /\A(?<type>\w+)(?:\((?<scope>[^)]+)\))?(?<breaking>!)?:\s*(?<description>.+)\z/

  module_function

  def version_file(root) = File.join(root, "lib/stockerly/version.rb")

  def changelog_file(root) = File.join(root, "CHANGELOG.md")

  def git(*args, root:)
    out, status = Open3.capture2("git", "-C", root, *args)
    raise "git #{args.join(' ')} exited #{status.exitstatus}" unless status.success?

    out
  end

  # --match keeps pre-2.0-evolve out of the range: only v* tags are releases,
  # and plain `git describe` would happily pick a marker tag.
  def last_version_tag(root:)
    out, status = Open3.capture2("git", "-C", root, "describe", "--tags", "--abbrev=0", "--match", "v*")
    status.success? ? out.strip : nil
  end

  def current_version(root:)
    File.read(version_file(root))[/VERSION\s*=\s*"([^"]+)"/, 1]
  end

  # A patch bump off a pre-release drops the suffix and keeps the numbers, so
  # 0.1.0-rc1 releases as 0.1.0 rather than 0.1.1.
  def bump(version, kind)
    major, minor, patch = version.split("-").first.split(".").map(&:to_i)

    case kind
    when "major" then "#{major + 1}.0.0"
    when "minor" then "#{major}.#{minor + 1}.0"
    when "patch" then version.include?("-") ? "#{major}.#{minor}.#{patch}" : "#{major}.#{minor}.#{patch + 1}"
    else raise ArgumentError, USAGE
    end
  end

  def commits_since(tag, root:)
    range = tag ? "#{tag}..HEAD" : "HEAD"
    log   = git("log", range, "--no-merges", "--pretty=format:%H\t%s", root: root)

    log.lines(chomp: true).reject(&:empty?).map do |line|
      sha, subject = line.split("\t", 2)
      { sha: sha, subject: subject.to_s }
    end
  end

  def parse_subject(subject)
    match = SUBJECT.match(subject)
    return nil unless match

    { type: match[:type], scope: match[:scope], description: match[:description], breaking: !match[:breaking].nil? }
  end

  def group(commits)
    classified    = commits.map { |commit| classify(commit) }
    carried, lost = classified.partition { |commit| commit[:label] }

    {
      groups:   carried.group_by { |commit| commit[:type] },
      breaking: classified.select { |commit| commit[:breaking] },
      dropped:  lost
    }
  end

  # Either a :label, which is the section it goes under, or a :why, which is what
  # the release pull request is told instead.
  def classify(commit)
    parsed = parse_subject(commit[:subject])
    return commit.merge(why: "not a conventional commit") if parsed.nil?

    type   = parsed[:type]
    placed = TYPE_LABELS.key?(type) ? { label: TYPE_LABELS[type] } : { why: silenced(type) }

    commit.merge(parsed, placed)
  end

  def silenced(type)
    SILENT_TYPES.fetch(type, "unknown type #{type.inspect}")
  end

  def format_entry(version, date, grouped, carried: "")
    prose    = carried.strip
    breaking = grouped[:breaking]
    parts    = [ "## [#{version}] - #{date}", "" ]

    parts.push(prose, "") unless prose.empty?
    parts.concat(section("Breaking Changes", breaking)) if breaking.any?
    labelled(grouped[:groups]).each { |label, entries| parts.concat(section(label, entries)) }

    parts.join("\n")
  end

  # Grouped by label rather than by type: perf, refactor and style all read as
  # Changed, and iterating types prints that heading once per type that has one.
  def labelled(groups)
    TYPE_LABELS.each_key.with_object({}) do |type, acc|
      entries = groups[type]
      next if entries.to_a.empty?

      (acc[TYPE_LABELS[type]] ||= []).concat(entries)
    end
  end

  def section(label, entries)
    [ "### #{label}", "" ] + entries.map { |entry| bullet(entry) } + [ "" ]
  end

  def bullet(entry)
    scope = entry[:scope]
    "- #{scope ? "**#{scope}:** " : ""}#{entry[:description]}"
  end

  # head · whatever was written under [Unreleased] by hand · the older entries ·
  # the link definitions. The hand-written body is carried into the new entry
  # rather than left under [Unreleased], where the next heading would orphan it.
  def split_changelog(text)
    head, marker, tail = text.partition(UNRELEASED)
    raise "CHANGELOG.md has no #{UNRELEASED} heading" if marker.empty?

    body, links    = split_at(tail, /^\[[^\]]+\]:/)
    carried, older = split_at(body, /^## \[/)

    { head: head, carried: carried.strip, older: older.strip, links: links.strip }
  end

  # Everything before the first line the pattern matches, and everything from it on.
  def split_at(text, pattern)
    index = text.index(pattern)
    index ? [ text[0...index], text[index..] ] : [ text, "" ]
  end

  def compose(parts, entry:, version:, previous_tag:)
    text = [
      "#{parts[:head]}#{UNRELEASED}",
      "",
      entry.strip,
      "",
      parts[:older],
      "",
      link_block(parts[:links], version, previous_tag)
    ].join("\n")

    "#{text.gsub(/\n{3,}/, "\n\n").strip}\n"
  end

  # The older definitions are kept: dropping them turns every `## [x.y.z]`
  # heading above into literal text, since those headings are reference links.
  def link_block(links, version, previous_tag)
    kept    = links.lines(chomp: true).reject { |line| line.start_with?("[Unreleased]:") }
    compare = previous_tag ? "#{REPO_URL}/compare/#{previous_tag}...v#{version}" : "#{REPO_URL}/releases/tag/v#{version}"

    ([ "[Unreleased]: #{REPO_URL}/compare/v#{version}...HEAD", "[#{version}]: #{compare}" ] + kept).join("\n")
  end

  def write_version(version, root:)
    path = version_file(root)
    File.write(path, File.read(path).sub(/VERSION\s*=\s*"[^"]+"/, %(VERSION = "#{version}")))
  end

  def report_dropped(dropped)
    return if dropped.empty?

    warn "release_changelog: #{dropped.size} commit(s) are not in this entry"
    dropped.each { |commit| warn "  #{commit[:sha][0, 7]} #{commit[:subject]}  — #{commit[:why]}" }
  end

  def main(argv, root: ROOT)
    dry_run = !argv.delete("--dry-run").nil?
    kind    = argv.shift
    raise ArgumentError, USAGE unless BUMPS.include?(kind)

    release(bump(current_version(root: root), kind), root: root, dry_run: dry_run)
  end

  def release(version, root:, dry_run:)
    changelog    = changelog_file(root)
    previous_tag = last_version_tag(root: root)
    grouped      = group(commits_since(previous_tag, root: root))
    parts        = split_changelog(File.read(changelog))
    entry        = format_entry(version, Date.today.to_s, grouped, carried: parts[:carried])

    report_dropped(grouped[:dropped])

    if dry_run
      puts entry
      return version
    end

    write_version(version, root: root)
    File.write(changelog, compose(parts, entry: entry, version: version, previous_tag: previous_tag))
    puts "lib/stockerly/version.rb and CHANGELOG.md updated for v#{version}"

    version
  end
end

ReleaseChangelog.main(ARGV) if __FILE__ == $PROGRAM_NAME
