module Identity
  module UseCases
    class CreateFirstAdmin < ApplicationUseCase
      def call(params:)
        return Failure([ :setup_complete, "Setup already completed" ]) if User.exists?

        attrs = yield validate(Contracts::CreateFirstAdminContract, params)
        user = yield persist(attrs)
        bootstrap_platform!
        _ = yield publish(Events::FirstAdminCreated.new(user_id: user.id, email: user.email))

        Success(user)
      end

      private

      def persist(attrs)
        user = User.new(
          full_name: attrs[:full_name],
          email: attrs[:email],
          password: attrs[:password],
          password_confirmation: attrs[:password_confirmation],
          role: :admin,
          is_verified: true,
          email_verified_at: Time.current
        )
        user.save ? Success(user) : Failure([ :validation, user.errors.to_hash ])
      end

      def bootstrap_platform!
        create_site_defaults!
        create_integrations!
        create_market_indices!
        create_fx_rates!
      end

      def create_site_defaults!
        { "maintenance_mode" => "false" }.each do |key, default|
          SiteConfig.find_or_create_by!(key: key) do |c|
            c.value = default
          end
        end
      end

      # The limits live in one place; this used to carry its own copy and had
      # drifted from it.
      def create_integrations!
        integrations = MarketData::Domain::ProviderDefaults::ALL.map { |name, attrs| attrs.merge(provider_name: name) }

        integrations.each do |attrs|
          Integration.find_or_create_by!(provider_name: attrs[:provider_name]) do |i|
            i.provider_type = attrs[:provider_type]
            i.requires_api_key = attrs[:requires_api_key]
            i.connection_status = :disconnected
            i.max_requests_per_minute = attrs[:max_requests_per_minute]
            i.daily_call_limit = attrs[:daily_call_limit]
            i.settings = attrs[:settings] || {}
          end
        end
      end

      def create_market_indices!
        indices = [
          { symbol: "SPX", name: "S&P 500", exchange: "NYSE" },
          { symbol: "NDX", name: "NASDAQ 100", exchange: "NASDAQ" },
          { symbol: "DJI", name: "DOW JONES", exchange: "NYSE" },
          { symbol: "UKX", name: "FTSE 100", exchange: "LSE" },
          { symbol: "IPC", name: "IPC Mexico", exchange: "BMV" },
          { symbol: "VIX", name: "CBOE Volatility", exchange: "CBOE" }
        ]

        indices.each do |attrs|
          MarketIndex.find_or_create_by!(symbol: attrs[:symbol]) do |i|
            i.name = attrs[:name]
            i.exchange = attrs[:exchange]
            i.value = 0
            i.change_percent = 0
          end
        end
      end

      def create_fx_rates!
        pairs = [
          { base_currency: "USD", quote_currency: "EUR", rate: 0.92 },
          { base_currency: "USD", quote_currency: "MXN", rate: 17.25 },
          { base_currency: "USD", quote_currency: "GBP", rate: 0.79 }
        ]

        pairs.each do |attrs|
          FxRate.find_or_create_by!(base_currency: attrs[:base_currency], quote_currency: attrs[:quote_currency]) do |r|
            r.rate = attrs[:rate]
            r.fetched_at = Time.current
          end
        end
      end
    end
  end
end
