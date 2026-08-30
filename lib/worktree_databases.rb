require "open3"

# The databases this Postgres server holds for each checkout, and which of them
# no longer have a worktree behind them.
module WorktreeDatabases
  Error = Class.new(StandardError)

  NAME = /\A(?<prefix>.+)_(?:development|test)(?:_cache|_queue|_cable)?\z/

  Group = Struct.new(:prefix, :databases, :worktree, keyword_init: true) do
    def orphan?
      worktree.nil?
    end
  end

  module_function

  def groups(database_names: existing_database_names, worktree_paths: live_worktree_paths)
    raise Error, "no worktrees found — refusing to treat every database as an orphan" if worktree_paths.empty?

    by_prefix = worktree_paths.to_h { |path| [ Stockerly::Checkout.prefix_for(path), path ] }
    scope = by_prefix.keys.first

    database_names
      .filter_map { |name| [ name[NAME, :prefix], name ] }
      .select { |prefix, _| prefix&.start_with?(scope) }
      .group_by(&:first)
      .map { |prefix, pairs| Group.new(prefix: prefix, databases: pairs.map(&:last).sort, worktree: by_prefix[prefix]) }
      .sort_by(&:prefix)
  end

  def orphans(**)
    groups(**).select(&:orphan?)
  end

  def drop!(group)
    raise Error, "#{group.prefix} still has a worktree at #{group.worktree}" unless group.orphan?

    connection = ActiveRecord::Base.connection
    group.databases.each do |name|
      connection.execute("DROP DATABASE IF EXISTS #{connection.quote_table_name(name)} WITH (FORCE)")
    end
  end

  def existing_database_names
    ActiveRecord::Base.connection.select_values(
      "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname"
    )
  end

  # `git worktree list` prints the main worktree first, and its name is what
  # scopes the databases this module is allowed to look at.
  def live_worktree_paths
    output, status = Open3.capture2("git", "-C", Rails.root.to_s, "worktree", "list", "--porcelain")
    raise Error, "could not read the worktree list from git" unless status.success?

    output.lines.filter_map { |line| line.split(" ", 2).last.strip if line.start_with?("worktree ") }
  end
end
