module Stockerly
  # One checkout, one set of databases — git worktrees would otherwise share them (#486).
  module Checkout
    module_function

    def database_prefix
      ENV.fetch("DATABASE_PREFIX") { prefix_for(File.expand_path("../..", __dir__)) }
    end

    def prefix_for(path)
      File.basename(path.to_s).gsub(/[^a-zA-Z0-9_]/, "_")
    end
  end
end
