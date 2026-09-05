module Stockerly
  # One checkout, one set of databases — git worktrees would otherwise share them (#486).
  #
  # A worktree's databases carry the main checkout's name too, so the name says
  # where they came from: `stockerly__vix_index_symbols`, not
  # `vix_index_symbols`. Without it a worktree under `.claude/worktrees/` names
  # its databases after a directory nobody can trace, and WorktreeDatabases --
  # which is only allowed to look at prefixes belonging to this checkout --
  # cannot see them to prune them. 92 orphans accumulated that way.
  module Checkout
    module_function

    # Postgres truncates an identifier at 63 bytes, and the longest suffix the
    # app appends is `_development_cache`.
    MAX_PREFIX = 63 - "_development_cache".length
    JOIN = "__".freeze

    def database_prefix
      ENV.fetch("DATABASE_PREFIX") { prefix_for(File.expand_path("../..", __dir__)) }
    end

    def prefix_for(path)
      root = File.expand_path(path.to_s)
      own = sanitize(File.basename(root))
      main = main_checkout_for(root)
      return own unless main

      truncate("#{sanitize(File.basename(main))}#{JOIN}#{own}")
    end

    def sanitize(name)
      name.gsub(/[^a-zA-Z0-9_]/, "_")
    end

    # A worktree's `.git` is a file pointing into the main checkout's
    # `.git/worktrees/`; the main checkout's is a directory. Reading it beats
    # shelling out to git, which this runs too early to afford.
    def main_checkout_for(root)
      pointer = File.join(root, ".git")
      return unless File.file?(pointer)

      File.read(pointer)[%r{gitdir:\s*(.+?)/\.git/worktrees/}, 1]
    rescue SystemCallError
      nil
    end

    def truncate(prefix)
      prefix.length <= MAX_PREFIX ? prefix : prefix[0, MAX_PREFIX]
    end
  end
end
