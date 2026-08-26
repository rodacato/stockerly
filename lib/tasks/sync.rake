namespace :stockerly do
  desc "Sync code-defined integrations with database records (idempotent)"
  task sync: :environment do
    sync_integrations
  end

  def sync_integrations
    provider_names = DataSourceRegistry.all.map(&:integration_name).uniq
    created = 0

    provider_names.each do |name|
      defaults = MarketData::Domain::ProviderDefaults.for(name)

      Integration.find_or_create_by!(provider_name: name) do |i|
        i.provider_type          = defaults[:provider_type]
        i.requires_api_key       = defaults[:requires_api_key]
        i.connection_status      = :disconnected
        i.max_requests_per_minute = defaults[:max_requests_per_minute]
        i.daily_call_limit       = defaults[:daily_call_limit]
        i.settings               = defaults[:settings] if defaults[:settings]
        created += 1
      end
    end

    existing = provider_names.size - created
    puts "Integrations: #{created} created, #{existing} already exist, #{Integration.count} total"
    report_limit_drift(provider_names)
    report_orphans(provider_names)
  end

  # Sync only ever creates, so a provider retired from the registry keeps its
  # row -- and its card in the admin -- long after the code that used it is gone.
  def report_orphans(provider_names)
    orphans = Integration.where.not(provider_name: provider_names).order(:provider_name)
    return if orphans.empty?

    puts "\nNo longer in the registry (delete from Admin > Integrations if retired):"
    orphans.each { |i| puts "  #{i.provider_name} -- #{i.provider_type}" }
  end

  # Defaults apply on create only, so an existing row keeps whatever it had.
  # That is deliberate -- it protects a tuned limit -- but silent drift is how a
  # provider ends up throttled to a number nobody chose.
  def report_limit_drift(provider_names)
    drifted = provider_names.filter_map do |name|
      defaults = MarketData::Domain::ProviderDefaults::ALL[name]
      next if defaults.nil?

      integration = Integration.find_by(provider_name: name)
      next if integration.nil?

      changes = %i[max_requests_per_minute daily_call_limit].filter_map do |field|
        next if integration.public_send(field) == defaults[field]

        "#{field}: #{integration.public_send(field).inspect} vs #{defaults[field].inspect}"
      end

      "  #{name} -- #{changes.join(', ')}" if changes.any?
    end

    return if drifted.empty?

    puts "\nLimits differ from the defaults in this file (kept as-is):"
    puts drifted
  end
end
