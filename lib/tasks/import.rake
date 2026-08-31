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

  desc "Delete every trade and everything derived from it (dry run; pass COMMIT=1 to write)"
  task reset_trades: :environment do
    portfolio = ImportTradesCli.user.portfolio or abort "No portfolio yet — run the Setup Wizard at /setup first."

    ImportTradesCli.print_reset(portfolio, commit: ENV["COMMIT"] == "1")
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
  def self.read(path)
    abort "Usage: bin/rails stockerly:import_trades[path/to.csv]" if path.blank?
    abort "No such file: #{path}" unless File.exist?(path)

    Trading::Domain::CsvRows.call(text: File.read(path))
  rescue Trading::Domain::CsvRows::MissingHeader => e
    abort e.message
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

  # Everything downstream of a trade, so a re-import starts from nothing rather
  # than merging into half a history. The catalogue, FX rates, price history and
  # the portfolio row itself are deliberately left alone -- they are not derived
  # from trades and re-fetching them costs provider calls.
  def self.print_reset(portfolio, commit:)
    counts = ImportTradesReset.counts(portfolio)

    if counts.values.sum.zero?
      puts "Nothing to delete — the portfolio holds no trades."
      return
    end

    puts commit ? "Deleting:" : "DRY RUN — nothing deleted:"
    counts.each { |table, count| puts format("  %-18s %d", table, count) }

    unless commit
      puts "\nRe-run with COMMIT=1 to delete. Take a database backup first."
      return
    end

    ImportTradesReset.call(portfolio)
    puts "\nDone. inception_date cleared; import the oldest month first."
  end

  def self.abort_with(reason, details)
    warn "Import refused — #{reason}:"
    Array(details).each { |d| warn "  #{d.is_a?(Hash) ? d.inspect : d}" }
    warn "\nAdd the missing symbols at /tracked, then re-run." if reason == :unknown_symbols
    exit 1
  end
end

# The delete itself, apart from the printing so it can be tested without
# capturing stdout.
module ImportTradesReset
  TABLES = %i[trades positions snapshots dividend_payments].freeze

  def self.counts(portfolio)
    TABLES.index_with { |table| portfolio.public_send(table).count }
  end

  def self.call(portfolio)
    ActiveRecord::Base.transaction do
      # Ordered child-first: a position destroys its own trades, and letting it
      # do that mid-sweep would leave the trades relation counting rows that are
      # already gone.
      portfolio.trades.destroy_all
      portfolio.positions.destroy_all
      portfolio.snapshots.destroy_all
      portfolio.dividend_payments.destroy_all
      portfolio.update!(inception_date: nil)
    end
  end
end
