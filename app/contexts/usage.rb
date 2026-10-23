# ADR-032: the one door into the usage record. An event is written only while
# the owner's switch is on and only if the catalogue declares it; anything
# else, and any failure, records nothing and raises nothing.
module Usage
  SWITCH = "usage_tracking".freeze

  def self.enabled? = SiteConfig.enabled?(SWITCH)

  # When the switch last moved: the edge between weeks that were measured and
  # weeks that read zero only because nothing was recording.
  def self.switched_at = SiteConfig.where(key: SWITCH).pick(:updated_at)

  def self.record(name, screen: nil, **properties)
    return unless enabled?

    event = Domain::Catalogue.find(name)
    return unless event

    UsageEvent.create!(name: event.name, screen: screen.to_s.first(40).presence, properties: event.permit(properties),
                       occurred_at: Time.current)
  rescue StandardError => error
    Rails.logger.warn("[usage] #{name} not recorded: #{error.class}")
    nil
  end

  # The day counters stay on whatever the switch says (ADR-032 §7): a count per day, nothing else.
  def self.opened(path)
    AppOpen.record(path: path)
  rescue StandardError => error
    Rails.logger.warn("[usage] open of #{path} not counted: #{error.class}")
    nil
  end
end
