# A js: true spec asserts what CSS decides — which nav the viewport shows, what
# a breakpoint hides. Without `app/assets/builds/tailwind.css` every element is
# visible, so those assertions fail with "found aside nav visible" and send the
# reader hunting for a layout regression that is not there.
#
# The build is gitignored, so a fresh worktree or a clean checkout starts
# without it. This turns a misleading failure into an instruction.
RSpec.configure do |config|
  config.before(:each, js: true) do
    stylesheet = Rails.root.join("app/assets/builds/tailwind.css")

    next if stylesheet.exist? && stylesheet.size.positive?

    raise <<~MESSAGE
      Tailwind has not been built in this checkout, so no CSS is applied and
      every element renders visible. Any assertion about what a breakpoint
      hides will fail for that reason and not for a real one.

      Run: bin/rails tailwindcss:build
    MESSAGE
  end
end
