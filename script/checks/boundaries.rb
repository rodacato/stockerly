# frozen_string_literal: true

require_relative "support"

module Checks
  # ADR-002 decided one pair: Trading reads MarketData through the supplier's
  # public API; MarketData does not read Trading. The leak shape it names is a
  # *bare* constant — MarketIndex.major, FearGreedReading.latest_* — which is
  # why this looks for model names rather than namespaces.
  #
  # Only that pair is enforced. ADR-002's amendment of 2026-09-04 declares the
  # Alerts pairs too — Alerts→MarketData on the same terms, Alerts→Trading as a
  # dependency that does not exist — and extending this check to Alerts would
  # land green today. Identity reaching for Integration and MarketIndex in
  # CreateFirstAdmin is BND-02, still undecided; a check that invented that rule
  # would be enforcing an opinion.
  #
  # What this cannot see, per ADR-024: ownership by column. A job writing
  # Asset#name is a violation of ADR-024 and is invisible to a constant grep.
  class Boundaries < Check
    ID = "boundaries"
    TITLE = "ADR-002: Trading and MarketData read each other through the read API"

    OWNERS = {
      "administration" => %w[ErrorEvent Integration SiteConfig SiteConfigChange],
      "alerts"         => %w[AlertEvent AlertPreference AlertRule],
      "identity"       => %w[OtpRecoveryCode],
      "market_data"    => %w[
        AssetFundamental AssetPriceHistory CetesRateHistory Dividend EarningsEvent
        FearGreedReading FinancialStatement MarketHoliday MarketIndex MarketIndexHistory
        NewsArticle StockSplit TechnicalObservation TechnicalReading TrendScore
      ],
      "notifications"  => %w[Notification PushSubscription],
      "trading"        => %w[
        DividendPayment Portfolio PortfolioSnapshot Position SplitAdjustment Trade
        WatchlistItem
      ]
    }.freeze

    # ADR-024 §"The other seven models": shared kernel, infrastructure, or a
    # single owner whose reads are explicitly permitted from anywhere.
    SHARED = %w[ApplicationRecord Asset AuditLog FxRate FxRateHistory SystemLog User].freeze

    ENFORCED_PAIR = %w[trading market_data].freeze

    def run
      unclassified + bare_constants + namespace_leaks
    end

    private

    # Keeps OWNERS honest: a new model has to be classified before it can leak.
    def unclassified
      known = OWNERS.values.flatten + SHARED
      Checks.files("app/models/*.rb").filter_map do |path|
        constant = File.basename(path, ".rb").split("_").map(&:capitalize).join
        next if known.include?(constant)

        Violation.new(path: path, line: 1,
                      message: "#{constant} is not classified in script/checks/boundaries.rb — give it an owner")
      end
    end

    def bare_constants
      ENFORCED_PAIR.flat_map do |context|
        foreign = OWNERS.fetch(ENFORCED_PAIR.find { |other| other != context })
        pattern = /(?<![A-Za-z0-9_:.])(#{foreign.join('|')})\b/
        scan(Checks.files("app/contexts/#{context}/**/*.rb")) do |line|
          match = line[pattern, 1]
          match && "reads #{match}, an ActiveRecord model the other context owns — go through its Queries::/UseCases:: API"
        end
      end
    end

    def namespace_leaks
      scan(Checks.files("app/contexts/market_data/**/*.rb")) { |line|
        "MarketData reads Trading — ADR-002 makes the dependency one-directional" if line.match?(/(?<![A-Za-z0-9_:.])Trading::/)
      } + scan(Checks.files("app/contexts/trading/**/*.rb")) { |line|
        "Trading reaches into MarketData::Gateways — gateways are a MarketData internal" if line.include?("MarketData::Gateways::")
      }
    end
  end
end
