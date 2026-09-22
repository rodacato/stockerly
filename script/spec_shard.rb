#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints one shard's spec files, for splitting the suite across CI runners.
#
# Greedy bin-packing by file size: biggest file first, into whichever group is
# lightest. Deterministic — the sort breaks ties by path, so every runner
# computes the same split from the same tree without talking to the others.
#
#   SHARDS=4 SHARD=2 ruby script/spec_shard.rb

shards = Integer(ENV.fetch("SHARDS"))
shard  = Integer(ENV.fetch("SHARD"))
raise ArgumentError, "SHARD #{shard} outside 1..#{shards}" unless (1..shards).cover?(shard)

groups = Array.new(shards) { { size: 0, files: [] } }

Dir["spec/**/*_spec.rb"].sort_by { |path| [ -File.size(path), path ] }.each do |path|
  lightest = groups.min_by { |group| [ group[:size], groups.index(group) ] }
  lightest[:size] += File.size(path)
  lightest[:files] << path
end

puts groups.fetch(shard - 1)[:files].sort
