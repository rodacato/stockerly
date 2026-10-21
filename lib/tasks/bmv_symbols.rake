namespace :data do
  desc "Resolve DataBursatil emisora_serie for MX assets that have no mapping (#311)"
  task resolve_bmv_symbols: :environment do
    use_case = Administration::UseCases::Assets::ResolveBmvSymbols
    provider = use_case::PROVIDER

    pending = use_case.new.pending_assets
    if pending.empty?
      puts "resolve_bmv_symbols — nothing to do (every MX asset already carries a #{provider} symbol)"
      next
    end

    puts "Probing #{pending.size} asset(s). A rejected request costs no credits, so an unknown name is free to ask about."

    outcome = use_case.call do |asset, answer|
      base = asset.symbol.to_s.upcase.delete_suffix(".MX")
      puts(answer ? "  #{asset.symbol} -> #{answer}" : "  #{asset.symbol} -- neither #{base} nor #{base}* answered")
    end

    puts ""
    puts "Resolved #{outcome.resolved.size}, unresolved #{outcome.unresolved.size}."

    next if outcome.unresolved.empty?

    puts ""
    puts "These need a mapping by hand -- one unmapped issuer fails the whole bulk call:"
    outcome.unresolved.each { |symbol| puts "  #{symbol}" }
  end
end
