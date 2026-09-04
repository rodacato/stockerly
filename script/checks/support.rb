# frozen_string_literal: true

require "yaml"

# Shared plumbing for the ADR conventions a grep can actually see. Each check
# reports violations as file+line and is held green by a baseline of what
# already exists — the same bargain .rubocop_todo.yml makes.
module Checks
  ROOT = File.expand_path("../..", __dir__)
  BASELINE_PATH = File.join(ROOT, "script/checks/baseline.yml")
  ALLOW_MARKER = "stockerly:allow"
  QUOTES = [ '"', "'" ].freeze

  Violation = Struct.new(:path, :line, :message, keyword_init: true)

  class << self
    def registry
      @registry ||= []
    end

    def register(check)
      registry << check
    end

    def files(*globs)
      globs.flat_map { |glob| Dir.glob(File.join(ROOT, glob)) }
        .select { |path| File.file?(path) }
        .map { |path| path.delete_prefix("#{ROOT}/") }
        .sort
    end

    # Comment text is blanked rather than removed, so line numbers survive.
    def source(path)
      body = File.read(File.join(ROOT, path))
      case File.extname(path)
      when ".erb"
        blank_blocks(body, /<%#.*?%>/m).lines
      when ".js", ".css"
        blank_line_comments(blank_blocks(body, %r{/\*.*?\*/}m), "//").lines
      else
        blank_line_comments(body, "#").lines
      end
    end

    def raw_lines(path)
      @raw_lines ||= {}
      @raw_lines[path] ||= File.readlines(File.join(ROOT, path))
    end

    def allowed?(path, index, check_id)
      marker = "#{ALLOW_MARKER}(#{check_id})"
      lines = raw_lines(path)
      [ lines[index], (index.positive? ? lines[index - 1] : nil) ].compact.any? { |line| line.include?(marker) }
    end

    def baseline
      @baseline ||= File.exist?(BASELINE_PATH) ? (YAML.safe_load_file(BASELINE_PATH) || {}) : {}
    end

    private

    def blank_blocks(body, pattern)
      body.gsub(pattern) { |match| match.gsub(/[^\n]/, " ") }
    end

    def blank_line_comments(body, opener)
      return body unless body.include?(opener)

      body.lines.map { |line| line.include?(opener) ? blank_from_comment(line, opener) : line }.join
    end

    # Blanks from the first comment opener that is not inside a string literal.
    def blank_from_comment(line, opener)
      quote = nil
      index = 0
      while index < line.length
        char = line[index]
        if quote
          quote = nil if char == quote && line[index - 1] != "\\"
        elsif QUOTES.include?(char)
          quote = char
        elsif line[index, opener.length] == opener && !(opener == "#" && line[index, 2] == '#{')
          return line[0, index] + line[index..].gsub(/[^\n]/, " ")
        end
        index += 1
      end
      line
    end
  end

  # A check is an id, a title and a #run returning violations.
  class Check
    def self.inherited(subclass)
      super
      Checks.register(subclass)
    end

    def id = self.class::ID
    def title = self.class::TITLE

    def scan(paths)
      paths.flat_map do |path|
        Checks.source(path).each_with_index.filter_map do |line, index|
          next if Checks.allowed?(path, index, id)

          message = yield(line, path)
          message && Violation.new(path: path, line: index + 1, message: message)
        end
      end
    end
  end

  # Splits violations into "already recorded" and "new", and flags baseline rows
  # that no longer describe reality so the file cannot rot into a permanent pass.
  class Ratchet
    def initialize(check_id)
      @recorded = Checks.baseline.fetch(check_id, nil) || {}
    end

    def verdict(violations)
      by_path = violations.group_by(&:path)
      unexpected = by_path.flat_map do |path, found|
        allowance = @recorded.dig(path, "count").to_i
        found.length > allowance ? found.last(found.length - allowance) : []
      end
      { unexpected: unexpected, stale: stale_rows(by_path) }
    end

    private

    def stale_rows(by_path)
      @recorded.filter_map do |path, row|
        found = by_path.fetch(path, []).length
        allowed = row.fetch("count", 0)
        "#{path}: baseline allows #{allowed}, code has #{found}" if found < allowed
      end
    end
  end

  class Reporter
    def initialize(check_id, title)
      @check_id = check_id
      @title = title
    end

    def call(violations)
      result = Ratchet.new(@check_id).verdict(violations)
      print_stale(result[:stale])
      return pass(violations.length) if result[:unexpected].empty?

      print_failure(result[:unexpected])
    end

    private

    def pass(recorded)
      note = recorded.zero? ? "" : " (#{recorded} recorded in script/checks/baseline.yml)"
      puts "  ok    #{@check_id} — #{@title}#{note}"
      true
    end

    def print_failure(violations)
      puts "  FAIL  #{@check_id} — #{@title}"
      violations.each { |v| puts "        #{v.path}:#{v.line} #{v.message}" }
      puts "        Escape hatch: `#{ALLOW_MARKER}(#{@check_id}) <reason>` on the line or the one above it,"
      puts "        or record the file in script/checks/baseline.yml with a reason. Do not delete the check."
      false
    end

    def print_stale(stale)
      return if stale.empty?

      puts "  note  #{@check_id} — the baseline is ahead of the code; trim these rows:"
      stale.each { |row| puts "        #{row}" }
    end
  end
end
