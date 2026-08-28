require "csv"

namespace :stockerly do
  desc "Import trades from a CSV (dry run by default; pass COMMIT=1 to write)"
  task :import_trades, [ :path ] => :environment do |_t, args|
    rows = ImportTradesCli.read(args[:path])
    dry_run = ENV["COMMIT"] != "1"

    case Trading::UseCases::ImportTrades.call(user: ImportTradesCli.user, rows: rows, dry_run: dry_run)
    in Dry::Monads::Success(report) then ImportTradesCli.print_report(report)
    in Dry::Monads::Failure[ reason, details ] then ImportTradesCli.abort_with(reason, details)
    end
  end

  desc "Undo an import by the external ids in its CSV"
  task :undo_import, [ :path ] => :environment do |_t, args|
    ids = ImportTradesCli.read(args[:path]).filter_map { |row| row[:external_id].presence }
    abort "No external_id column in #{args[:path]} — nothing to undo by." if ids.empty?

    result = Trading::UseCases::UndoImport.call(portfolio: ImportTradesCli.user.portfolio, external_ids: ids)
    puts "Removed #{result[:removed]} trade(s); snapshots rebuilt from #{result[:from]}."
  end
end

# Rake-only presentation. Lives here rather than in app/ because nothing else
# renders an import to a terminal.
module ImportTradesCli
  KEYS = %i[asset_symbol side shares price_per_share fee currency executed_at external_id net_amount].freeze

  def self.read(path)
    abort "Usage: bin/rails stockerly:import_trades[path/to.csv]" if path.blank?
    abort "No such file: #{path}" unless File.exist?(path)

    CSV.read(path, headers: true).map { |row| row.to_h.symbolize_keys.slice(*KEYS) }
  end

  def self.user
    User.first or abort "No user yet — run the Setup Wizard at /setup first."
  end

  def self.print_report(report)
    puts "#{report[:dry_run] ? 'DRY RUN — nothing written' : 'Imported'}: #{report[:imported]} trade(s)"
    puts "  range    #{report[:earliest_on]} -> #{report[:latest_on]}"
    puts "  invested #{format('%.2f', report[:invested])}"
    puts "  symbols  #{report[:symbols].join(' ')}"
    report[:skipped].each { |s| puts "  skipped  #{s[:asset_symbol]} #{s[:external_id]} (already imported)" }
    puts "\nRe-run with COMMIT=1 to write." if report[:dry_run]
  end

  def self.abort_with(reason, details)
    warn "Import refused — #{reason}:"
    Array(details).each { |d| warn "  #{d.is_a?(Hash) ? d.inspect : d}" }
    warn "\nAdd the missing symbols at /tracked, then re-run." if reason == :unknown_symbols
    exit 1
  end
end
