namespace :data do
  desc "Resolve DataBursatil emisora_serie for MX assets that have no mapping (#311)"
  task resolve_bmv_symbols: :environment do
    provider = MarketData::Gateways::DataBursatilGateway::PROVIDER

    # Only what this provider actually serves. CETES are Mexican and priced by
    # Banxico, not by an exchange, so probing them spends requests to learn
    # nothing and reports them unresolvable forever. The registry already knows
    # which asset types route here.
    served = lambda do |asset|
      DataSourceRegistry
        .for_capability(:prices, market: asset.market, asset_type: asset.asset_type)
        .any? { |source| source.integration_name == provider }
    end

    pending = Asset.where(country: "MX")
                   .select(&served)
                   .reject { |asset| asset.provider_symbols.key?(provider) }

    if pending.empty?
      puts "resolve_bmv_symbols — nothing to do (every MX asset already carries a #{provider} symbol)"
      next
    end

    puts "Probing #{pending.size} asset(s). A rejected request costs no credits, so an unknown name is free to ask about."

    gateway = MarketData::Gateways::DataBursatilGateway.new
    resolved = []
    unresolved = []

    pending.each do |asset|
      base = asset.symbol.to_s.upcase.delete_suffix(".MX")
      # The serie is mandatory and Yahoo omits it when it is `*`, so the bare
      # name is tried first and the starred form second. Nothing else is
      # guessed: a name that answers neither is reported, not invented.
      answer = [ base, "#{base}*" ].find { |candidate| gateway.fetch_price(candidate).success? }

      if answer
        asset.update!(provider_symbols: asset.provider_symbols.merge(provider => answer))
        resolved << [ asset.symbol, answer ]
        puts "  #{asset.symbol} -> #{answer}"
      else
        unresolved << asset.symbol
        puts "  #{asset.symbol} -- neither #{base} nor #{base}* answered"
      end
    end

    puts ""
    puts "Resolved #{resolved.size}, unresolved #{unresolved.size}."

    next if unresolved.empty?

    puts ""
    puts "These need a mapping by hand -- one unmapped issuer fails the whole bulk call:"
    unresolved.each { |symbol| puts "  #{symbol}" }
  end
end
