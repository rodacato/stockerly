namespace :data do
  desc "Look up BMV issuers and their series through DataBursatil's filtered catalogue (ONB-5, #379)"
  task :bmv_issuers, [ :symbols ] => :environment do |_task, args|
    # The 17 largest IPC issuers, written issuer+serie because the BMV rejects
    # a bare name: WALMEX is a 400 and WALMEX* is a 200 (probed 2026-08-26).
    # Pass SYMBOLS to override.
    default = %w[
      WALMEX AMXL FEMSAUBD GFNORTEO CEMEXCPO GMEXICOB TLEVISACPO BIMBOA
      KIMBERA ASURB ALFAA GAPB OMAB PINFRA ORBIA LIVEPOLC-1 ELEKTRA
    ]
    symbols = args[:symbols].to_s.split(/[\s,]+/).map(&:upcase).compact_blank
    symbols = default if symbols.empty?

    begin
      gateway = MarketData::Gateways::DataBursatilGateway.new
    rescue MarketData::Gateways::ApiKeyNotConfiguredError => e
      # An operator task reports a missing token as a sentence, not a backtrace.
      abort "#{e.message}\nNothing was queried."
    end

    before = gateway.remaining_credits(force: true)
    puts "Querying #{symbols.size} issuer(s). Credits before: #{before || "unknown"}."
    puts "Each filtered call costs about 6 credits; the unfiltered catalogue costs 2,181 (#379)."
    puts ""

    found = []
    missing = []

    symbols.each do |symbol|
      result = gateway.fetch_issuers(symbol)

      if result.success?
        found << symbol
        puts "#{symbol} -> OK"
        # Printed raw on purpose: this task exists to learn the row's shape,
        # not to assume it. What the first real run prints is what any parser
        # should later be written against.
        puts JSON.pretty_generate(result.value!).lines.first(12).join.rstrip
        puts ""
      else
        missing << symbol
        puts "#{symbol} -- #{result.failure.inspect}"
      end
    end

    after = gateway.remaining_credits(force: true)
    puts ""
    puts "Found #{found.size}, missing #{missing.size}."
    puts "Credits after: #{after || "unknown"}#{" (spent #{before - after})" if before && after}."

    if missing.any?
      puts ""
      puts "These answered nothing. Do NOT add them to the catalogue on faith --"
      puts "a symbol that does not resolve creates a broken asset on a first run:"
      missing.each { |symbol| puts "  #{symbol}" }
    end

    puts ""
    puts "Catalogue form for what resolved -- country MX is what routes an asset"
    puts "to this provider (Asset#market), so data_source is left to the sync:"
    found.each do |symbol|
      puts %({ symbol: "#{symbol}.MX", name: "", asset_type: "stock", exchange: "BMV", country: "MX", currency: "MXN" },)
    end
  end
end
