namespace :db do
  desc "List the database groups on this server and the worktree each one belongs to"
  task worktrees: :environment do
    WorktreeDatabases.groups.each do |group|
      home = group.worktree || "no worktree — #{group.databases.size} orphan databases"
      puts format("  %-30s %s", group.prefix, home)
    end
  end

  namespace :worktrees do
    desc "Drop the database groups whose worktree is gone (FORCE=1 skips the prompt)"
    task prune: :environment do
      orphans = WorktreeDatabases.orphans

      if orphans.empty?
        puts "Nothing to prune — every database group still has a worktree."
        next
      end

      orphans.each { |group| puts "  #{group.prefix}: #{group.databases.join(', ')}" }
      count = orphans.sum { |group| group.databases.size }

      unless ENV["FORCE"] == "1"
        abort "Not a terminal — re-run with FORCE=1 to drop these." unless $stdin.tty?
        print "Drop #{count} databases? Type 'yes' to confirm: "
        abort "Aborted, nothing was dropped." unless $stdin.gets.to_s.strip == "yes"
      end

      orphans.each do |group|
        WorktreeDatabases.drop!(group)
        puts "Dropped #{group.prefix}"
      end
    end
  end
end
