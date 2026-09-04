# frozen_string_literal: true

require_relative "support"

module Checks
  # ADR-006's criterion, which until now was applied by whoever remembered it —
  # which is how it reached 13 violations before #535 counted them.
  #
  # A use case belongs on SimpleUseCase when all four are true: no yield, no
  # validate(, no base-class publish( — an inline EventBus.publish is the gray
  # zone the ADR blesses — and no caller that destructures its result. Test 4 is
  # the one that gets dropped, and dropping it is what inflated #535's count
  # from 13 to 21.
  #
  # The second check is the invariant behind the criterion: a use case that can
  # never return a Failure must not return a Result.
  class UseCases < Check
    ID = "use-cases"
    TITLE = "ADR-006: the base class matches what the use case needs"

    CALLER_GLOBS = [ "app/**/*.rb", "app/**/*.erb", "lib/**/*.rb" ].freeze

    WINDOW = 12

    def run
      @callers = load_callers
      use_cases.flat_map { |use_case| verdict(use_case) }
    end

    private

    def verdict(use_case)
      violations = []
      if use_case[:base] == "ApplicationUseCase" && four_tests(use_case).empty?
        violations << flag(use_case, "uses none of yield / validate( / publish( and no caller " \
                                     "destructures its result — ADR-006 makes it a SimpleUseCase")
      elsif returns_result?(use_case) && failure_path(use_case).empty?
        violations << flag(use_case, "returns a Result with no reachable Failure — ADR-006's " \
                                     "invariant: a use case that never fails must not return a Result")
      end
      violations.compact
    end

    # The four tests, in ADR-006's order. An inline EventBus.publish is not
    # publish( — the lookbehind is what keeps the third test honest.
    def four_tests(use_case)
      body = use_case[:body]
      tests = []
      tests << :yield if body.match?(/(?<![\w.])yield\b/)
      tests << :validate if body.match?(/(?<![\w.])validate\(/)
      tests << :publish if body.match?(/(?<![\w.])publish\(/)
      tests << :caller if pattern_matched_caller?(use_case)
      tests
    end

    # ADR-006 spells the invariant out as grep-checkable: no literal Failure, no
    # validate(, and no propagated callee failure — the last one being a yield
    # or a hand-rolled `return result if result.failure?`.
    def failure_path(use_case)
      body = use_case[:body]
      tests = []
      tests << :yield if body.match?(/(?<![\w.])yield\b/)
      tests << :validate if body.match?(/(?<![\w.])validate\(/)
      tests << :failure if body.match?(/(?<![\w.])Failure[(\[]/)
      tests << :propagated if body.match?(/\.failure[?!]/)
      tests
    end

    def returns_result?(use_case)
      use_case[:base] == "ApplicationUseCase" || use_case[:body].match?(/(?<![\w.])Success\(/)
    end

    def pattern_matched_caller?(use_case)
      @callers.any? { |path, lines| destructured_in?(lines, use_case[:constant], path, use_case[:path]) }
    end

    # ADR-006's test 4: case/in on the result, a read of .failure, or a yield
    # inside another use case's do-notation. Anything looser counts a nearby
    # unrelated `in Success` as a caller and lets the drift through.
    def destructured_in?(lines, constant, path, own_path)
      return false if path == own_path

      name = Regexp.escape(constant)
      lines.each_with_index.any? do |line, index|
        next false unless line.include?("#{constant}.")
        next true if line.match?(/yield\s+#{name}\b/) || line.match?(/case\s+#{name}\./)

        variable = line[/(\w+)\s*=\s*[^=]*#{name}\./, 1]
        next destructures?(lines[index + 1, WINDOW], variable) if variable

        # The result handed straight to a helper, as the 2FA controller does.
        receiver = line[/(\w+)\(\s*#{name}\./, 1]
        receiver && helper_destructures?(lines, receiver)
      end
    end

    def destructures?(window, variable)
      window.to_a.join.match?(/case\s+#{Regexp.escape(variable)}\b|#{Regexp.escape(variable)}\.failure\b/)
    end

    def helper_destructures?(lines, method)
      start = lines.index { |line| line.match?(/def\s+#{Regexp.escape(method)}\b/) }
      return false unless start

      parameter = lines[start][/def\s+\w+\(\s*(\w+)/, 1]
      parameter && destructures?(lines[start + 1, WINDOW], parameter)
    end

    def use_cases
      Checks.files("app/contexts/*/use_cases/**/*.rb").filter_map do |path|
        body = Checks.source(path).join
        base = body[/class\s+\w+\s+<\s+(ApplicationUseCase|SimpleUseCase)\b/, 1]
        next unless base

        { path: path, body: body, base: base, constant: constant_for(path) }
      end
    end

    def constant_for(path)
      path.delete_prefix("app/contexts/").delete_suffix(".rb")
        .split("/").map { |part| part.split("_").map(&:capitalize).join }.join("::")
    end

    def load_callers
      cache = {}
      Checks.files(*CALLER_GLOBS).each { |path| cache[path] = Checks.source(path) }
      cache
    end

    def flag(use_case, message)
      index = Checks.source(use_case[:path]).index { |line| line.include?("class ") }.to_i
      return nil if Checks.allowed?(use_case[:path], index, id)

      Violation.new(path: use_case[:path], line: index + 1, message: message)
    end
  end
end
